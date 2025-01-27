package elk.util;

interface RectPackNode {
	public var x : Int;
	public var y : Int;
	public var width : Int;
	public var height : Int;
}

private typedef Row = {
	var topY : Int;
	var endX : Int;
	var height : Int;
}

private typedef Rect = {
	var x : Int;
	var y : Int;
	var height : Int;
	var width : Int;
}

class RectPacker<T : RectPackNode> {
	static var MAX_WIDTH = 1024 << 2;
	static var MAX_HEIGHT = 1024 << 2;

	var freeRects : Array<Rect>;
	var rows : Array<Row>;

	public var nodes : Array<T>;

	public var padding(default, set) : Int = 1;

	public var autoResize = true;

	public var width : Int = 0;
	public var height : Int = 0;

	var internalWidth = 64;
	var internalHeight = 64;

	var overlaps : Array<{right : Rect, bottom : Rect}> = [];

	public function new(width = 128, height = 128) {
		this.internalWidth = width;
		this.internalHeight = height;

		reset();
	}

	public function reset() {
		nodes = [];
		rows = [];
		freeRects = [];
		overlaps = [];
		width = 0;
		height = 0;
	}

	public function resize(width : Int, height : Int) {
		var nodes = this.nodes;
		this.internalWidth = width;
		this.internalHeight = height;
		reset();

		nodes.sort((a, b) -> {
			return -Std.int((a.height) - (b.height));
		});

		for (n in nodes) add(n);
	}

	public function refresh(?startWidth, ?startHeight) {
		resize(startWidth ?? internalWidth, startHeight ?? internalHeight);
	}

	inline function newRow(height : Int) : Row {
		var lastRow = rows.length > 0 ? rows[rows.length - 1] : null;
		var topY = lastRow != null ? lastRow.topY + lastRow.height : 0;

		if( lastRow != null ) {
			addFreeRect({
				y : lastRow.topY + padding,
				x : lastRow.endX + padding,
				height : lastRow.height - padding,
				width : this.internalWidth - lastRow.endX - padding,
			});
		}

		if( topY + height > this.internalHeight - padding ) {
			return null;
		}

		var row : Row = {
			topY : topY,
			endX : 0,
			height : height,
		}
		rows.push(row);

		return row;
	}

	inline function addFreeRect(r : Rect) {
		if( r.width < 2 + padding || r.height < 2 + padding ) {
			return;
		}

		freeRects.push(r);
		freeRects.sort((a, b) -> {
			return (a.height + a.width) - (b.height - b.width);
		});
	}

	inline function fitsRow(row : Row, node : T) {
		var endX = row.endX + padding;
		var height = node.height + padding;
		var width = node.width + padding;

		return height <= row.height && endX + width < this.internalWidth;
	}

	inline function findFreeRect(node : T) {
		var res = null;
		for (r in freeRects) {
			if( r.width < node.width ) continue;
			if( r.height < node.height ) continue;
			res = r;
			break;
		}

		return res;
	}

	inline function splitRect(rect : Rect, node : T) {
		var rightRect : Rect = {
			x : rect.x + node.width + padding,
			y : rect.y,
			width : rect.width - node.width - padding,
			height : rect.height,
		}
		addFreeRect(rightRect);

		var bottomRect : Rect = {
			x : rect.x,
			y : rect.y + node.height + padding,
			width : rect.width,
			height : rect.height - node.height - padding,
		}
		addFreeRect(bottomRect);

		overlaps.push({right : rightRect, bottom : bottomRect});
	}

	private inline function pushNode(node : T) {
		nodes.push(node);
		width = Std.int(Math.max(width, node.x + node.width + padding));
		height = Std.int(Math.max(height, node.y + node.height + padding));
	}

	public function add(node : T) {
		var freeCell = findFreeRect(node);
		if( freeCell != null ) {
			freeRects.remove(freeCell);
			for (o in overlaps) {
				if( o.bottom == freeCell ) {
					o.right.height = o.bottom.y - o.right.y;
					overlaps.remove(o);
					break;
				} else if( o.right == freeCell ) {
					o.bottom.width = o.right.x - o.bottom.x;
					overlaps.remove(o);
					break;
				}
			}

			splitRect(freeCell, node);
			node.x = freeCell.x;
			node.y = freeCell.y;
			pushNode(node);
			return node;
		}

		var curRow = rows.length > 0 ? rows[rows.length - 1] : newRow(node.height + padding);
		if( curRow != null && !fitsRow(curRow, node) ) {
			curRow = newRow(node.height + padding);
		}

		if( curRow == null ) {
			if( !autoResize ) return null;
			var sizeInc = Std.int(Math.max(node.width, node.height));
			/*
				var newWidth = this.internalWidth << 1;
				var newHeight = this.internalHeight << 1;
			 */
			var newWidth = internalWidth + node.width;
			var newHeight = internalHeight + node.height + rows.length * padding * 2;
			if( newWidth >= MAX_WIDTH || newHeight >= MAX_HEIGHT ) {
				throw "Can't resize, size exceeds maximum";
			}

			resize(newWidth, newHeight);
			return add(node);
		}

		node.x = curRow.endX + padding;
		node.y = curRow.topY + padding;

		curRow.endX += node.width + padding;

		if( node.height < curRow.height + padding ) {
			addFreeRect({
				x : node.x,
				y : node.y + node.height + padding,
				width : node.width,
				height : curRow.height - node.height - padding * 2,
			});
		}

		pushNode(node);

		return node;
	}

	public function remove(node : T) {
		if( !nodes.contains(node) ) return;
		nodes.remove(node);
		addFreeRect({
			x : node.x,
			y : node.y,
			width : node.width,
			height : node.height,
		});
	}

	function set_padding(padding) {
		this.padding = padding;
		refresh();
		return this.padding;
	}
}
