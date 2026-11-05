let storage = new LocalStorage();

interface CardRow {
  name: string;
  daysText: string;
  emoji: string;
}

/**
 * 桌面卡片：2×2 显示最近一个事件，2×4 显示最近三条
 * 数据由主应用通过 formProvider.updateForm 推送
 */
@Entry(storage)
@Component
struct WidgetCard {
  @LocalStorageProp('eventName') eventName: string = '暂无事件';
  @LocalStorageProp('daysText') daysText: string = '--';
  @LocalStorageProp('dateText') dateText: string = '去应用里添加一个日子';
  @LocalStorageProp('itemsJson') itemsJson: string = '[]';
  @LocalStorageProp('wide') wide: string = '0';

  rows(): CardRow[] {
    try {
      const arr = JSON.parse(this.itemsJson) as CardRow[];
      return arr;
    } catch (err) {
      return [];
    }
  }

  build() {
    Column() {
      if (this.wide === '1') {
        this.WideLayout()
      } else {
        this.SquareLayout()
      }
    }
    .width('100%')
    .height('100%')
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  SquareLayout() {
    Column({ space: 6 }) {
      Text('记得那天')
        .fontSize(12)
        .fontColor('#666666')
        .maxLines(1)

      Text(this.eventName)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#222222')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Blank()

      Text(this.daysText)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#C0392B')
        .maxLines(1)

      Text(this.dateText)
        .fontSize(11)
        .fontColor('#666666')
        .maxLines(1)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  WideLayout() {
    Column({ space: 8 }) {
      Row() {
        Text('记得那天')
          .fontSize(12)
          .fontColor('#666666')
        Blank()
        Text(this.dateText)
          .fontSize(11)
          .fontColor('#666666')
          .maxLines(1)
      }
      .width('100%')

      Divider().color('#E8EAED')

      ForEach(this.rows(), (row: CardRow) => {
        Row({ space: 8 }) {
          Text(row.emoji)
            .fontSize(14)
          Text(row.name)
            .fontSize(14)
            .fontColor('#222222')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(row.daysText)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#C0392B')
            .maxLines(1)
        }
        .width('100%')
      }, (row: CardRow) => row.name + row.daysText)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
