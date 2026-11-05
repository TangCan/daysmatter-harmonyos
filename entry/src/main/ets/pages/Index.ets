import {
  CountdownEvent,
  daysBetween,
  formatDate,
  effectiveDate,
  daysToEvent,
  categoryOption,
  CategoryOption,
  CATEGORY_OPTIONS
} from '../model/CountdownEvent';
import { EventStore } from '../common/EventStore';
import { CardSync } from '../common/CardSync';
import { common } from '@kit.AbilityKit';

interface StepCellParam {
  label: string;
  value: number;
}

interface ChipParam {
  key: string;
  label: string;
  emoji: string;
}

@Entry
@Component
struct Index {
  @State events: CountdownEvent[] = [];
  @State filter: string = 'all';
  @State keyword: string = '';
  @State showSearch: boolean = false;
  @State sortBy: string = 'date';
  @State showPanel: boolean = false;
  @State editingId: string = '';
  @State formName: string = '';
  @State formNote: string = '';
  @State formCategory: string = 'birthday';
  @State formRepeat: boolean = false;
  @State showPrivacy: boolean = false;
  @State pickedDate: Date = new Date();
  @State selYear: number = new Date().getFullYear();
  @State selMonth: number = new Date().getMonth() + 1;
  @State selDay: number = new Date().getDate();
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private privacyUrl: string = 'https://tangcan.github.io/daysmatter-harmonyos/privacy';

  aboutToAppear(): void {
    // 合规要求：首次启动必须在用户同意隐私政策后才进入使用
    this.showPrivacy = !EventStore.isPrivacyAgreed(this.context);
    this.reload();
  }

  async reload(): Promise<void> {
    const list = await EventStore.load(this.context);
    list.sort((a: CountdownEvent, b: CountdownEvent) => a.targetDate.localeCompare(b.targetDate));
    this.events = list;
    // 兜底：应用每次打开时刷新桌面卡片（覆盖卡片先于数据添加等场景）
    await CardSync.updateAllCards(this.context, list);
  }

  agreePrivacy(): void {
    EventStore.setPrivacyAgreed(this.context, true);
    this.showPrivacy = false;
  }

  refusePrivacy(): void {
    try {
      this.context.terminateSelf();
    } catch (err) {
      // Previewer 环境无法退出，忽略
    }
  }

  openPrivacyLink(): void {
    try {
      this.context.openLink(this.privacyUrl);
    } catch (err) {
      // Previewer 环境无法跳转，忽略
    }
  }

  /**
   * 过滤 + 排序后的展示列表：置顶优先，其次按日期或添加时间
   */
  visibleEvents(): CountdownEvent[] {
    let list = this.events;
    if (this.filter !== 'all') {
      list = list.filter((e: CountdownEvent) => e.category === this.filter);
    }
    const kw = this.keyword.trim().toLowerCase();
    if (kw.length > 0) {
      list = list.filter((e: CountdownEvent) =>
        e.name.toLowerCase().includes(kw) || e.note.toLowerCase().includes(kw));
    }
    const result = list.slice();
    result.sort((a: CountdownEvent, b: CountdownEvent) => {
      if (a.pinned !== b.pinned) {
        return a.pinned ? -1 : 1;
      }
      if (this.sortBy === 'created') {
        return b.createdAt - a.createdAt;
      }
      return daysToEvent(a) - daysToEvent(b);
    });
    return result;
  }

  summaryText(): string {
    if (this.events.length === 0) {
      return '开始记录第一个重要日子';
    }
    let bestName = this.events[0].name;
    let bestDays = daysToEvent(this.events[0]);
    for (const e of this.events) {
      const d = daysToEvent(e);
      if (d < bestDays) {
        bestDays = d;
        bestName = e.name;
      }
    }
    let tail = '';
    if (bestDays === 0) {
      tail = '就是今天';
    } else if (bestDays > 0) {
      tail = `${bestDays} 天后`;
    } else {
      tail = `${-bestDays} 天前`;
    }
    return `共 ${this.events.length} 个日子 · 最近「${bestName}」${tail}`;
  }

  dateLine(item: CountdownEvent): string {
    const cat = categoryOption(item.category).label;
    if (item.repeatYearly) {
      return `${item.targetDate} · ${cat} · 每年`;
    }
    return `${item.targetDate} · ${cat}`;
  }

  async saveEvent(): Promise<void> {
    const name = this.formName.trim();
    if (name.length === 0) {
      return;
    }
    const dateStr = formatDate(this.pickedDate);
    if (this.editingId.length > 0) {
      this.events = this.events.map((e: CountdownEvent) => {
        if (e.id !== this.editingId) {
          return e;
        }
        const updated = CountdownEvent.fromJson(e);
        updated.name = name;
        updated.targetDate = dateStr;
        updated.category = this.formCategory;
        updated.note = this.formNote.trim();
        updated.repeatYearly = this.formRepeat;
        return updated;
      });
    } else {
      const e = new CountdownEvent();
      e.id = Date.now().toString();
      e.name = name;
      e.targetDate = dateStr;
      e.category = this.formCategory;
      e.note = this.formNote.trim();
      e.repeatYearly = this.formRepeat;
      e.pinned = false;
      e.createdAt = Date.now();
      this.events = this.events.concat(e);
    }
    this.closePanel();
    await EventStore.save(this.context, this.events);
    await CardSync.updateAllCards(this.context, this.events);
  }

  async deleteEvent(item: CountdownEvent): Promise<void> {
    this.events = this.events.filter((e: CountdownEvent) => e.id !== item.id);
    await EventStore.save(this.context, this.events);
    await CardSync.updateAllCards(this.context, this.events);
  }

  async togglePin(item: CountdownEvent): Promise<void> {
    this.events = this.events.map((e: CountdownEvent) => {
      if (e.id !== item.id) {
        return e;
      }
      const updated = CountdownEvent.fromJson(e);
      updated.pinned = !e.pinned;
      return updated;
    });
    await EventStore.save(this.context, this.events);
    await CardSync.updateAllCards(this.context, this.events);
  }

  openCreate(): void {
    this.editingId = '';
    this.formName = '';
    this.formNote = '';
    this.formCategory = 'birthday';
    this.formRepeat = false;
    this.pickedDate = new Date();
    this.syncStepper();
    this.showPanel = true;
  }

  openEdit(item: CountdownEvent): void {
    this.editingId = item.id;
    this.formName = item.name;
    this.formNote = item.note;
    this.formCategory = item.category;
    this.formRepeat = item.repeatYearly;
    this.pickedDate = new Date(item.targetDate + 'T00:00:00');
    this.syncStepper();
    this.showPanel = true;
  }

  closePanel(): void {
    this.showPanel = false;
    this.editingId = '';
    this.formName = '';
    this.formNote = '';
  }

  badgeColor(days: number): string {
    if (days < 0) {
      return '#666666';
    } else if (days === 0) {
      return '#A32D2D';
    } else if (days <= 7) {
      return '#C0392B';
    } else if (days <= 30) {
      return '#8F5A00';
    }
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
    let y = this.selYear;
    let m = this.selMonth;
    let d = this.selDay;
    if (label === '年') {
      y += delta;
    } else if (label === '月') {
      m += delta;
      if (m > 12) {
        m = 1;
        y += 1;
      } else if (m < 1) {
        m = 12;
        y -= 1;
      }
    } else {
      d += delta;
      if (d > this.daysInMonth(y, m)) {
        d = 1;
        m += 1;
        if (m > 12) {
          m = 1;
          y += 1;
        }
      } else if (d < 1) {
        m -= 1;
        if (m < 1) {
          m = 12;
          y -= 1;
        }
        d = this.daysInMonth(y, m);
      }
    }
    if (y < 1900 || y > 2080) {
      return;
    }
    d = Math.min(d, this.daysInMonth(y, m));
    // 不倒计时过去的日期：仅对"一次性"事件生效；每年重复的事件保留原始日期（如出生年份）
    if (!this.formRepeat) {
      const today = new Date();
      const today0 = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      if (new Date(y, m - 1, d).getTime() < today0.getTime()) {
        return;
      }
    }
    this.selYear = y;
    this.selMonth = m;
    this.selDay = d;
    this.pickedDate = new Date(y, m - 1, d);
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // ---------- 顶部标题 + 工具条 ----------
        Row() {
          Column({ space: 2 }) {
            Text('记得那天')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F2328')
            Text(this.summaryText())
              .fontSize(12)
              .fontColor('#666666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text(this.showSearch ? '取消' : '搜索')
            .fontSize(13)
            .fontColor('#2B6CB0')
            .padding({ left: 8, right: 8, top: 6, bottom: 6 })
            .onClick(() => {
              this.showSearch = !this.showSearch;
              if (!this.showSearch) {
                this.keyword = '';
              }
            })
          Text(this.sortBy === 'date' ? '按日期' : '按添加')
            .fontSize(13)
            .fontColor('#2B6CB0')
            .padding({ left: 8, right: 4, top: 6, bottom: 6 })
            .onClick(() => {
              this.sortBy = this.sortBy === 'date' ? 'created' : 'date';
            })
        }
        .width('100%')
        .padding({ left: 20, right: 12, top: 16, bottom: 4 })

        if (this.showSearch) {
          TextInput({ placeholder: '搜索名称或备注', text: this.keyword })
            .height(40)
            .placeholderColor('#666666')
            .placeholderFont({ size: 14 })
            .fontColor('#1F2328')
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .margin({ left: 16, right: 16, top: 6 })
            .onChange((value: string) => {
              this.keyword = value;
            })
        }

        // ---------- 分类筛选 ----------
        Scroll() {
          Row({ space: 8 }) {
            this.CategoryChip({ key: 'all', label: '全部', emoji: '📋' })
            ForEach(CATEGORY_OPTIONS, (c: CategoryOption) => {
              this.CategoryChip({ key: c.key, label: c.label, emoji: c.emoji })
            }, (c: CategoryOption) => c.key)
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .height(46)
        .align(Alignment.Start)

        // ---------- 列表 ----------
        if (this.visibleEvents().length === 0 && !this.showPanel) {
          Column({ space: 10 }) {
            Text(this.events.length === 0 ? '📅' : '🔍').fontSize(52)
            Text(this.events.length === 0 ? '还没有任何倒数日' : '没有符合条件的日子')
              .fontSize(16)
              .fontColor('#444444')
            Text(this.events.length === 0 ? '点击右下角 + 添加第一个重要日子' : '试试换个分类或关键词')
              .fontSize(13)
              .fontColor('#666666')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 10 }) {
            ForEach(this.visibleEvents(), (item: CountdownEvent) => {
              ListItem() {
                this.EventCard(item)
              }
              .swipeAction({ start: this.PinButton(item), end: this.DeleteButton(item) })
            }, (item: CountdownEvent) => `${item.id}-${item.pinned}-${item.targetDate}-${item.name}-${item.category}`)
          }
          .layoutWeight(1)
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })
        }

        Row() {
          Text('关于与隐私声明')
            .fontSize(12)
            .fontColor('#666666')
            .onClick(() => {
              this.openPrivacyLink();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 6, bottom: 10 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F6F8')

      Button('+')
        .width(56)
        .height(56)
        .fontSize(28)
        .type(ButtonType.Circle)
        .backgroundColor('#2B6CB0')
        .margin(20)
        .onClick(() => {
          this.openCreate();
        })

      // ---------- 添加 / 编辑面板 ----------
      if (this.showPanel) {
        this.EditPanel()
      }

      // ---------- 首次启动隐私弹窗 ----------
      if (this.showPrivacy) {
        this.PrivacyDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CategoryChip($$: ChipParam) {
    Row({ space: 4 }) {
      Text($$.emoji).fontSize(13)
      Text($$.label)
        .fontSize(13)
        .fontColor(this.filter === $$.key ? '#FFFFFF' : '#333333')
    }
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .borderRadius(16)
    .backgroundColor(this.filter === $$.key ? '#2B6CB0' : '#FFFFFF')
    .onClick(() => {
      this.filter = $$.key;
    })
  }

  @Builder
  StepCell($$: StepCellParam) {
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
          this.stepDate($$.label, 1);
        })
      Text(`${$$.value} ${$$.label}`)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2328')
        .backgroundColor('#F1F3F5')
        .borderRadius(8)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .minFontSize(13)
        .maxFontSize(17)
      Button('▼')
        .width(64)
        .height(30)
        .fontSize(14)
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#E8EAED')
        .fontColor('#222222')
        .onClick(() => {
          this.stepDate($$.label, -1);
        })
    }
  }

  @Builder
  DateStepper() {
    Row({ space: 10 }) {
      this.StepCell({ label: '年', value: this.selYear })
      this.StepCell({ label: '月', value: this.selMonth })
      this.StepCell({ label: '日', value: this.selDay })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  EditPanel() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
        })

      Column({ space: 12 }) {
        Row() {
          Text(this.editingId.length > 0 ? '编辑日子' : '添加日子')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2328')
          Blank()
          Text('关闭')
            .fontSize(14)
            .fontColor('#666666')
            .padding(4)
            .onClick(() => {
              this.closePanel();
            })
        }
        .width('100%')

        Scroll() {
          Column({ space: 12 }) {
            TextInput({ placeholder: '事件名称，如：妈妈的生日', text: this.formName })
              .height(44)
              .placeholderColor('#666666')
              .placeholderFont({ size: 15 })
              .fontColor('#1F2328')
              .backgroundColor('#F1F3F5')
              .borderRadius(10)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.formName = value;
              })

            Row() {
              Text('分类')
                .fontSize(13)
                .fontColor('#666666')
                .width(48)
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(CATEGORY_OPTIONS, (c: CategoryOption) => {
                  Text(`${c.emoji} ${c.label}`)
                    .fontSize(12)
                    .fontColor(this.formCategory === c.key ? '#FFFFFF' : '#333333')
                    .backgroundColor(this.formCategory === c.key ? '#2B6CB0' : '#F1F3F5')
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .borderRadius(14)
                    .margin({ right: 8, bottom: 6 })
                    .onClick(() => {
                      this.formCategory = c.key;
                    })
                }, (c: CategoryOption) => c.key)
              }
              .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)

            this.DateStepper()

            Row() {
              Column({ space: 2 }) {
                Text('每年重复')
                  .fontSize(14)
                  .fontColor('#1F2328')
                Text('生日、纪念日过完自动滚到明年')
                  .fontSize(11)
                  .fontColor('#666666')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.formRepeat })
                .selectedColor('#2B6CB0')
                .onChange((isOn: boolean) => {
                  this.formRepeat = isOn;
                })
            }
            .width('100%')

            TextInput({ placeholder: '备注（可选），如：记得买蛋糕', text: this.formNote })
              .height(44)
              .placeholderColor('#666666')
              .placeholderFont({ size: 15 })
              .fontColor('#1F2328')
              .backgroundColor('#F1F3F5')
              .borderRadius(10)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.formNote = value;
              })
          }
          .width('100%')
        }
        .constraintSize({ maxHeight: 360 })
        .scrollBar(BarState.Off)
        .width('100%')

        Button(this.editingId.length > 0 ? '保存修改' : '保存倒数日')
          .width('100%')
          .height(44)
          .backgroundColor('#2B6CB0')
          .enabled(this.formName.trim().length > 0)
          .opacity(this.formName.trim().length > 0 ? 1 : 0.45)
          .onClick(() => {
            this.saveEvent();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 18, topRight: 18 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  PrivacyLine(text: string) {
    Row({ space: 6 }) {
      Text('·')
        .fontSize(14)
        .fontColor('#444444')
      Text(text)
        .fontSize(13)
        .fontColor('#444444')
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  PrivacyDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#99000000')

      Column({ space: 12 }) {
        Text('隐私政策与数据说明')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2328')

        Text('欢迎使用「记得那天」。开始使用前，请阅读并同意我们的隐私政策。')
          .fontSize(14)
          .fontColor('#333333')

        Column({ space: 8 }) {
          this.PrivacyLine('本应用不收集、不上传任何个人信息，无需注册或登录')
          this.PrivacyLine('你添加的日期与备注仅保存在本机，卸载应用即删除')
          this.PrivacyLine('应用不含广告，不申请通讯录、位置、相机等任何敏感权限')
          this.PrivacyLine('你可随时在「关于与隐私声明」中查看完整政策')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .backgroundColor('#F5F6F8')
        .borderRadius(10)

        Text('查看完整《隐私政策》')
          .fontSize(14)
          .fontColor('#2B6CB0')
          .onClick(() => {
            this.openPrivacyLink();
          })

        Row({ space: 10 }) {
          Button('不同意')
            .layoutWeight(1)
            .height(42)
            .backgroundColor('#E8EAED')
            .fontColor('#333333')
            .onClick(() => {
              this.refusePrivacy();
            })
          Button('同意并继续')
            .layoutWeight(1)
            .height(42)
            .backgroundColor('#2B6CB0')
            .fontColor(Color.White)
            .onClick(() => {
              this.agreePrivacy();
            })
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .width('88%')
      .padding(20)
      .borderRadius(16)
      .backgroundColor(Color.White)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  EventCard(item: CountdownEvent) {
    Row({ space: 12 }) {
      Column({ space: 5 }) {
        Row({ space: 6 }) {
          Text(categoryOption(item.category).emoji)
            .fontSize(15)
          Text(item.name)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F2328')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          if (item.pinned) {
            Text('置顶')
              .fontSize(10)
              .fontColor('#8F5A00')
              .backgroundColor('#FFF1DC')
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(4)
          }
        }
        .width('100%')

        Text(this.dateLine(item))
          .fontSize(12)
          .fontColor('#666666')
          .maxLines(1)

        if (item.note.length > 0) {
          Text(item.note)
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      this.DaysBadge(daysToEvent(item))
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor(Color.White)
    .onClick(() => {
      this.openEdit(item);
    })
  }

  @Builder
  DaysBadge(days: number) {
    Column({ space: 2 }) {
      if (days === 0) {
        Text('今天')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.badgeColor(0))
      } else if (days < 0) {
        Text(`已过 ${-days}`)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.badgeColor(days))
        Text('天')
          .fontSize(11)
          .fontColor('#666666')
      } else {
        Text(`${days}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.badgeColor(days))
        Text('天')
          .fontSize(11)
          .fontColor('#666666')
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

  @Builder
  PinButton(item: CountdownEvent) {
    Button(item.pinned ? '取消置顶' : '置顶')
      .width(72)
      .height('100%')
      .type(ButtonType.Normal)
      .borderRadius(12)
      .backgroundColor('#8F5A00')
      .fontColor(Color.White)
      .fontSize(13)
      .margin({ right: 8 })
      .onClick(() => {
        this.togglePin(item);
      })
  }
}
