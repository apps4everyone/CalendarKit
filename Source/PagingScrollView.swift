import UIKit

protocol PagingScrollViewDelegate: class {
  func scrollviewDidScrollToViewAtIndex(_ index: Int)
}

public protocol ReusableView: class {
  func prepareForReuse()
}

open class PagingScrollView<T: UIView>: UIScrollView, UIScrollViewDelegate where T: ReusableView {

  var reusableViews = [T]()
  weak var viewDelegate: PagingScrollViewDelegate?

  var previousPage: CGFloat = 1
  var currentScrollViewPage: CGFloat {
    get {
      let width = bounds.width
      let centerOffsetX = contentOffset.x + width / 2

      let result = centerOffsetX / width - 0.5
      // Return central page if impossible to calculate (View has no size yet)
      return result.isNaN ? 1 : result
    }
  }

  var accumulator: CGFloat = 0
  var currentIndex: CGFloat {
    return round(currentScrollViewPage) + accumulator
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    configure()
  }

    required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configure()
  }

  func configure() {
    isPagingEnabled = true
    isDirectionalLockEnabled = true
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    delegate = self
  }

    override open func layoutSubviews() {
    super.layoutSubviews()
        
    
    realignViews()
  }

  open func recenterIfNecessary() {
    if reusableViews.isEmpty { return }
    let contentWidth = contentSize.width
    let centerOffsetX = (contentWidth - bounds.size.width) / 2

    let distanceFromCenter = contentOffset.x - centerOffsetX

    if fabs(distanceFromCenter) > (contentWidth / 3) {
      recenter()
    }
  }

  func recenter() {
    let contentWidth = contentSize.width
    let centerOffsetX = (contentWidth - bounds.size.width) / 2
    let distanceFromCenter = contentOffset.x - centerOffsetX

    if distanceFromCenter > 0 {
      reusableViews.shift(1)
      accumulator += 1
      reusableViews.last!.prepareForReuse()
    } else if distanceFromCenter < 0 {
      reusableViews.shift(-1)
      accumulator -= 1
      reusableViews.first!.prepareForReuse()
    }
    contentOffset = CGPoint(x: centerOffsetX, y: contentOffset.y)
  }

  func realignViews() {
    
    var contentRect = CGRect.zero
    
    for (index, subview) in reusableViews.enumerated() {
      subview.frame.origin.x = bounds.width * CGFloat(index)
      subview.frame.size = bounds.size
    }
  }
    
  func resizeScrollViewContentSize() {
    
    for subview in reusableViews {
        
        guard let timelineContainer = subview as? TimelineContainer else
        {
            debugPrint(subview)
            return
        }
        
        timelineContainer.layoutSubviews()
    }
}

  func scrollForward() {
    setContentOffset(CGPoint(x: contentOffset.x + bounds.width, y: 0), animated: true)
  }

  func scrollBackward() {
    setContentOffset(CGPoint(x: contentOffset.x - bounds.width, y: 0), animated: true)
  }

  func checkForPageChange() {
    recenter()
    if currentIndex != previousPage {
      viewDelegate?.scrollviewDidScrollToViewAtIndex(Int(currentScrollViewPage))
      previousPage = currentIndex
    }
  }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if decelerate {return}
    checkForPageChange()
  }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    checkForPageChange()
  }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    checkForPageChange()
  }
}
