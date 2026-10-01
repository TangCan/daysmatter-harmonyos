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
      return '#999999';
    } else if (days === 0) {
      return '#A32D2D';
    } else if (days <= 7) {
      return '#E24B4A';
    } else if (days <= 30) {
      return '#BA7517';
    }
    return '#185FA5';
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
            Text('还没有任何倒数日').fontSize(16).fontColor('#888888')
            Text('点击右下角 + 添加第一个重要日子').fontSize(13).fontColor('#AAAAAA')
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
            .fontColor('#999999')
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
        .backgroundColor(this.showAdd ? '#888888' : '#378ADD')
        .margin(20)
        .onClick(() => {
          this.showAdd = !this.showAdd;
          this.newName = '';
          this.pickedDate = new Date();
        })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  AddPanel() {
    Column({ space: 12 }) {
      TextInput({ placeholder: '事件名称，如：妈妈的生日', text: this.newName })
        .height(44)
        .onChange((value: string) => {
          this.newName = value;
        })

      DatePicker({ start: new Date(), selected: this.pickedDate })
        .height(120)
        .onDateChange((value: Date) => {
          this.pickedDate = value;
        })

      Button('保存倒数日')
        .width('100%')
        .backgroundColor('#378ADD')
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
          .fontColor('#999999')
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
        Text('天').fontSize(11).fontColor('#999999')
      } else {
        Text(`${days}`).fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.badgeColor(days))
        Text('天').fontSize(11).fontColor('#999999')
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
      .backgroundColor('#E24B4A')
      .fontColor(Color.White)
      .margin({ left: 8 })
      .onClick(() => {
        this.deleteEvent(item);
      })
  }
}
