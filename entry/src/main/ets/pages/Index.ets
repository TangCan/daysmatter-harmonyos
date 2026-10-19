import { CountdownEvent, daysBetween, formatDate } from '../model/CountdownEvent';
import { EventStore } from '../common/EventStore';
import { CardSync } from '../common/CardSync';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @State events: CountdownEvent[] = [];
  @State showAdd: boolean = false;
  @State newName: string = '';
  @State pickedDate: Date = new Date();
  @State selYear: number = new Date().getFullYear();
  @State selMonth: number = new Date().getMonth() + 1;
  @State selDay: number = new Date().getDate();
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private privacyUrl: string = 'https://tangcan.github.io/daysmatter-harmonyos/privacy';

  aboutToAppear(): void {
    this.reload();
  }

  async reload(): Promise<void> {
    const list = await EventStore.load(this.context);
    list.sort((a: CountdownEvent, b: CountdownEvent) => a.targetDate.localeCompare(b.targetDate));
    this.events = list;
    // 兜底：应用每次打开时刷新桌面卡片（覆盖卡片先于数据添加等场景）
    await CardSync.updateAllCards(this.context, list);
  }

  async addEvent(): Promise<void> {
    const name = this.newName.trim();
    if (name.length === 0) {
      return;
    }
    const e = new CountdownEvent();
    e.id = Date.now().toString();
    e.name = name;
    e.targetDate = formatDate(this.pickedDate);
    const combined = this.events.concat(e);
    combined.sort((a: CountdownEvent, b: CountdownEvent) => a.targetDate.localeCompare(b.targetDate));
    this.events = combined;
    this.showAdd = false;
    this.newName = '';
    await EventStore.save(this.context, this.events);
    await CardSync.updateAllCards(this.context, this.events);
  }

  async deleteEvent(item: CountdownEvent): Promise<void> {
    this.events = this.events.filter((e: CountdownEvent) => e.id !== item.id);
    await EventStore.save(this.context, this.events);
    await CardSync.updateAllCards(this.context, this.events);
  }

  badgeColor(days: number): string {
    if (days < 0) {
      return '#666666';
    } else if (days === 0) {
      return '#A32D2D';
    } else if (days <= 7) {
      return '#C0392B';
    } else if (days <= 30) {
      return '#8F5A00';    }
    return '#185FA5';
  }

  daysInMonth(y: number, m: number): number {
    return new Date(y, m, 0).getDate();
  }

  syncStepper(): void {
    this.selYear = this.pickedDate.getFullYear();
    this.selMonth = this.pickedDate.getMonth() + 1;
    this.selDay = this.pickedDate.getDate();
  }

  stepDate(label: string, delta: number): void {
    if (label === '年') {
      this.selYear += delta;
    } else if (label === '月') {
      this.selMonth += delta;
      if (this.selMonth > 12) {
        this.selMonth = 1;
        this.selYear += 1;
      } else if (this.selMonth < 1) {
        this.selMonth = 12;
        this.selYear -= 1;
      }
    } else {
      this.selDay += delta;
      const dim = this.daysInMonth(this.selYear, this.selMonth);
      if (this.selDay > dim) {
        this.selDay = 1;
        this.selMonth += 1;
        if (this.selMonth > 12) {
          this.selMonth = 1;
          this.selYear += 1;
        }
      } else if (this.selDay < 1) {
        this.selMonth -= 1;
        if (this.selMonth < 1) {
          this.selMonth = 12;
          this.selYear -= 1;
        }
        this.selDay = this.daysInMonth(this.selYear, this.selMonth);
      }
    }
    const y = Math.min(Math.max(this.selYear, 2020), 2080);
    if (y !== this.selYear) {
      this.selYear = y;
    }
    this.pickedDate = new Date(this.selYear, this.selMonth - 1, this.selDay);
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Text('记得那天')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .width('100%')
          .padding({ left: 20, top: 16, bottom: 8 })

        if (this.showAdd) {
          this.AddPanel()
        }

        if (this.events.length === 0 && !this.showAdd) {
          Column({ space: 12 }) {
            Text('📅').fontSize(56)
            Text('还没有任何倒数日').fontSize(16).fontColor('#666666')
            Text('点击右下角 + 添加第一个重要日子').fontSize(13).fontColor('#6B6B6B')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 12 }) {
            ForEach(this.events, (item: CountdownEvent) => {
              ListItem() {
                this.EventCard(item)
              }
              .swipeAction({ end: this.DeleteButton(item) })
            }, (item: CountdownEvent) => item.id)
          }
          .layoutWeight(1)
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 })
        }

        Row() {
          Text('关于与隐私声明')
            .fontSize(12)
            .fontColor('#666666')
            .onClick(() => {
              try {
                this.context.openLink(this.privacyUrl);
              } catch (err) {
                // Previewer 环境无法跳转，忽略
              }
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F6F8')

      Button(this.showAdd ? '×' : '+')
        .width(56)
        .height(56)
        .fontSize(28)
        .type(ButtonType.Circle)
        .backgroundColor(this.showAdd ? '#666666' : '#2B6CB0')
        .margin(20)
        .onClick(() => {
          this.showAdd = !this.showAdd;
          this.newName = '';
          this.pickedDate = new Date();
          this.syncStepper();
        })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  StepCell(label: string, value: number) {
    Column({ space: 4 }) {
      Button('▲')
        .width(64)
        .height(30)
        .fontSize(14)
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#E8EAED')
        .fontColor('#222222')
        .onClick(() => {
          this.stepDate(label, 1);
        })
      Text(`${value} ${label}`)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#222222')
        .backgroundColor('#F5F6F8')
        .borderRadius(8)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .minFontSize(14)
        .maxFontSize(18)
      Button('▼')
        .width(64)
        .height(30)
        .fontSize(14)
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#E8EAED')
        .fontColor('#222222')
        .onClick(() => {
          this.stepDate(label, -1);
        })
    }
  }

  @Builder
  DateStepper() {
    Row({ space: 10 }) {
      this.StepCell('年', this.selYear)
      this.StepCell('月', this.selMonth)
      this.StepCell('日', this.selDay)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  AddPanel() {
    Column({ space: 12 }) {
      TextInput({ placeholder: '事件名称，如：妈妈的生日', text: this.newName })
        .height(44)
        .placeholderColor('#666666')
        .placeholderFont({ size: 15 })
        .fontColor('#222222')
        .backgroundColor('#F1F3F5')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.newName = value;
        })

      this.DateStepper()

      Button('保存倒数日')
        .width('100%')
        .backgroundColor('#2B6CB0')
        .onClick(() => {
          this.addEvent();
        })
    }
    .width('100%')
    .padding(16)
    .margin({ left: 16, right: 16, bottom: 8 })
    .borderRadius(12)
    .backgroundColor(Color.White)
  }

  @Builder
  EventCard(item: CountdownEvent) {
    Row() {
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#222222')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.targetDate)
          .fontSize(13)
          .fontColor('#666666')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      this.DaysBadge(daysBetween(item.targetDate))
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor(Color.White)
  }

  @Builder
  DaysBadge(days: number) {
    Column({ space: 2 }) {
      if (days === 0) {
        Text('今天').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.badgeColor(0))
      } else if (days < 0) {
        Text(`已过 ${-days}`).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.badgeColor(days))
        Text('天').fontSize(11).fontColor('#666666')
      } else {
        Text(`${days}`).fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.badgeColor(days))
        Text('天').fontSize(11).fontColor('#666666')
      }
    }
    .alignItems(HorizontalAlign.End)
  }

  @Builder
  DeleteButton(item: CountdownEvent) {
    Button('删除')
      .width(64)
      .height('100%')
      .type(ButtonType.Normal)
      .borderRadius(12)
      .backgroundColor('#C0392B')
      .fontColor(Color.White)
      .margin({ left: 8 })
      .onClick(() => {
        this.deleteEvent(item);
      })
  }
}
