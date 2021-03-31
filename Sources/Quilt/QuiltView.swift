import SwiftUI

public enum QuiltLayoutDirection {
    case vertical
    case horizontal
}

struct BlockPosition : Hashable{
    var x : Int
    var y : Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine("x:\(x),y:\(y)".hash)
    }
}

public struct PatchSize : Hashable {
    var rowBlocksOccupied: Int
    var columnBlocksOccupied: Int
    
    public init(width: Int = 1, height: Int = 1) {
        self.rowBlocksOccupied = width
        self.columnBlocksOccupied = height
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine("rowBlocksOccupied:\(rowBlocksOccupied),columnBlocksOccupied:\(columnBlocksOccupied)".hash)
    }
}

public struct QuiltView<Data:RandomAccessCollection,Item:Hashable,Content:View> : View {
    let blockSizeInPixel : CGFloat
    let blocksToFit : Int
    var patches : [Patch<Content>] = [Patch<Content>]()
    private var patchIndexByPosition : [BlockPosition:Int] = [BlockPosition:Int]()
    
    public init( direction: QuiltLayoutDirection = .vertical,
                 blockSizeInPixel: CGFloat = .infinity,
                 blocksToFit: Int = 3,
                 @ViewBuilder content: @escaping () -> ForEach<Data,Item,Patch<Content>>) {
        self.blockSizeInPixel = blockSizeInPixel
        self.blocksToFit = blocksToFit
        let views = content()
        self.patches = views.data.enumerated().map{ (index, item) in
            computePositions( patch: views.content(item),
                              index: index,
                              blockedPositions: &patchIndexByPosition)
        }
    }
    
    fileprivate func computePositions(patch: Patch<Content>,
                          index: Int,
                          blockedPositions: inout [BlockPosition:Int] ) -> Patch<Content> {
        var returnPatch = patch
        enumerateAllOpenBlock { openPosition in
            var didFindPatch = true
            enumerateBlock(origin: openPosition, size: patch.size) { blockPosition in
                didFindPatch = blockedPositions[blockPosition] == nil
                return didFindPatch
            }
            
            if( didFindPatch ){
                returnPatch.position = openPosition
                enumerateBlock( origin: openPosition, size: patch.size) { blockPosition in
                    blockedPositions[blockPosition] = index
                    return true
                }
            }
            return (didFindPatch == false)
        }
        return returnPatch
    }
    
    fileprivate func enumerateAllOpenBlock( iterator:(BlockPosition)->Bool ){
        let rows : Int = .max
        for row in 0..<rows {
            for col in 0..<blocksToFit {
                let block = BlockPosition(x:col, y:row)
                if let _ = patchIndexByPosition[block] {} else {
                    if( iterator(block) == false ){
                        return
                    }
                }
            }
        }
    }
    
    fileprivate func enumerateBlock( origin:BlockPosition, size:PatchSize, iterator:(BlockPosition)->Bool ){
        for row in origin.y..<(origin.y + size.columnBlocksOccupied) {
            for col in origin.x..<(origin.x + size.rowBlocksOccupied) {
                if( iterator(BlockPosition(x: col, y: row)) == false ) {
                    return
                }
            }
        }
    }
    
    fileprivate func blockSize( quiltSize: CGSize) -> CGSize {
        let _blocksInPixel = blockSizeInPixel
        if( blockSizeInPixel == .infinity ) {
            let width = quiltSize.width / CGFloat(self.blocksToFit)
            let height = quiltSize.height / CGFloat(self.blocksToFit)
            return CGSize(width: width, height: height)
        }
        else {
            return CGSize(width: _blocksInPixel, height: _blocksInPixel)
        }
    }
    
    func patchSizeInPixel( patch:PatchSize, quiltSize:CGSize) -> CGSize {
        let blockSizeInPixel = self.blockSize(quiltSize: quiltSize)
        return CGSize(width: CGFloat(patch.rowBlocksOccupied) * blockSizeInPixel.width,
                      height: CGFloat(patch.columnBlocksOccupied) * blockSizeInPixel.height)
    }
    
    func patchPosition( patch: Patch<Content>, quiltSize:CGSize) -> CGPoint {
        let blockSize = self.blockSize(quiltSize: quiltSize)
        let _blockSizeInPixel_width = blockSize.width
        let _blockSizeInPixel_height = blockSize.height
        let rowMultiplier = CGFloat(patch.size.rowBlocksOccupied)
        let columnsMultiplier = CGFloat(patch.size.columnBlocksOccupied)
        let position = CGPoint(x: (CGFloat(patch.position.x) * _blockSizeInPixel_width) + ((_blockSizeInPixel_width * rowMultiplier)/2),
                               y: (CGFloat(patch.position.y) * _blockSizeInPixel_height) + ((_blockSizeInPixel_height * columnsMultiplier)/2))
        
        return position
    }
    
    public var body: some View {
        GeometryReader { gr in
            Group {
                ForEach(0..<self.patches.count) { index in
                    let patch = self.patches[index]
                    patch
                        .patchPosition(self.patchPosition(patch: patch, quiltSize: gr.size))
                        .patchSize(size:self.patchSizeInPixel(patch: patch.size, quiltSize: gr.size))
                }
            }
            .frame(idealWidth:gr.size.width, idealHeight: gr.size.height)
            
        }
    }
}

public struct Patch<T:View> : View{
    public typealias Body = T
    var content : T
    var size: PatchSize
    fileprivate var position : BlockPosition = BlockPosition( x: -1, y: -1)
    public init(size: PatchSize = PatchSize(), @ViewBuilder content: @escaping () -> T ){
        self.content = content()
        self.size = size
    }
    
    public var body: T {
        return content
    }
}

public extension View {
    fileprivate func patchSize(size: CGSize) -> some View {
        self.frame( width: size.width, height: size.height)
    }
    
    fileprivate func patchPosition(_ position:CGPoint) -> some View {
        self.position(position)
    }
    
    func patch(size:PatchSize) -> Patch<Self> {
        return Patch(size: size){ self }
    }
}
