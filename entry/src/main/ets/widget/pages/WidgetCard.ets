let storage = new LocalStorage();

/**
 * 2x2 桌面卡片：显示最近一个倒数日事件
 * 数据由主应用通过 formProvider.updateForm 推送（eventName / daysText）
 */
@Entry(storage)
@Component
struct WidgetCard {
  @LocalStorageProp('eventName') eventName: string = '暂无事件';
  @LocalStorageProp('daysText') daysText: string = '--';

  build() {
    Column({ space: 6 }) {
      Text('记得那天')
        .fontSize(12)
        .fontColor('#888888')
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
        .fontColor('#E24B4A')
        .maxLines(1)
    }
    .width('100%')
    .height('100%')
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}
