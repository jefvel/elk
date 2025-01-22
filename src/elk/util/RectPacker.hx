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
	var nodes : Array<T>;

	public var padding(default, set) : Int = 1;

	public var autoResize = true;

	public var width : Int = 1024 << 2;
	public var height : Int = 1024 << 2;

	public function new(width = 1024, height = 1024) {
		this.width = width;
		this.height = height;

		reset();
	}

	public function reset() {
		nodes = [];
		rows = [];
		freeRects = [];
	}

	public function resize(width : Int, height : Int) {
		var nodes = this.nodes;
		this.width = width;
		this.height = height;
		reset();

		nodes.sort((a, b) -> {
			return -Std.int((a.height) - (b.height));
		});

		for (n in nodes) add(n);
	}

	public function refresh(?startWidth = 128, ?startHeight = 128) {
		resize(startWidth ?? width, startHeight ?? height);
	}

	inline function newRow(height : Int) : Row {
		var lastRow = rows.length > 0 ? rows[rows.length - 1] : null;
		var topY = lastRow != null ? lastRow.topY + lastRow.height : 0;

		if( lastRow != null ) {
			addFreeRect({
				y : lastRow.topY + padding,
				x : lastRow.endX + padding,
				height : lastRow.height - padding,
				width : this.width - lastRow.endX - padding,
			});
		}

		if( topY + height > this.height - padding ) {
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
	}

	inline function fitsRow(row : Row, node : T) {
		var endX = row.endX + padding;
		var height = node.height + padding;
		var width = node.width + padding;

		return height <= row.height && endX + width < this.width;
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
			width : node.width,
			height : rect.height - node.height - padding,
		}
		addFreeRect(bottomRect);
	}

	public function add(node : T) {
		var freeCell = findFreeRect(node);
		if( freeCell != null ) {
			freeRects.remove(freeCell);
			splitRect(freeCell, node);
			node.x = freeCell.x;
			node.y = freeCell.y;
			nodes.push(node);
			return node;
		}

		var curRow = rows.length > 0 ? rows[rows.length - 1] : newRow(node.height + padding);
		if( curRow != null && !fitsRow(curRow, node) ) {
			curRow = newRow(node.height + padding);
		}

		if( curRow == null ) {
			if( !autoResize ) return null;
			var newWidth = this.width << 1;
			var newHeight = this.height << 1;
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

		nodes.push(node);

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
