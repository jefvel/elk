package elk.graphics;

import h3d.prim.UV;
import h3d.col.Point;
import h3d.prim.Polygon;
import h3d.prim.MeshPrimitive;
import h3d.col.Bounds;

class Quad extends h3d.prim.Polygon {
	var width:Float = 1.0;
	var height:Float = 1.0;
	var centered = true;

	public function new(width = 1.0, height = 1.0, centered = false) {
		var negativeScale = 0.;
		var positiveScale = 1.;

		if (centered) {
			negativeScale = 0.5;
			positiveScale = 0.5;
		}

		var points = [
			new Point(-width * negativeScale, 0, -height * negativeScale),
			new Point(-width * negativeScale, 0,  height * positiveScale),
			new Point( width * positiveScale, 0, -height * negativeScale),
			new Point( width * positiveScale, 0,  height * positiveScale)
		];
		
		var ids = [
			1, 3, 0,
			0, 3, 2,
		];

		var idx = new hxd.IndexBuffer(6);
		for (id in ids) idx.push(id);

		this.centered = centered;
		this.width = width;
		this.height = height;

		super(points, idx);
		addNormals();
		uvs = [
			new UV(0, 1),
			new UV(0, 0),
			new UV(1, 1),
			new UV(1, 0)
		];
	}

/*
	override function triCount() {
		return 2;
	}

	override function vertexCount() {
		return 4;
	}

	override function alloc(engine:h3d.Engine) {
		var v = new hxd.FloatBuffer(4 * 8);
		var negativeScale = 0.;
		var positiveScale = 1.;

		if (centered) {
			negativeScale = 0.5;
			positiveScale = 0.5;
		}

		// Pos
		v.push(-width * negativeScale);
		v.push(0);
		v.push(-height * negativeScale);

		// Norm
		v.push(0);
		v.push(1);
		v.push(0);

		// UV
		v.push(0);
		v.push(1);

		// Pos
		v.push(-width * negativeScale);
		v.push(0);
		v.push(height * positiveScale);
		// Norm
		v.push(0);
		v.push(1);
		v.push(0);
		// UV
		v.push(0);
		v.push(0);

		// Pos
		v.push(width * positiveScale);
		v.push(0);
		v.push(-height * negativeScale);
		// Norm
		v.push(0);
		v.push(1);
		v.push(0);
		// UV
		v.push(1);
		v.push(1);

		// Pos
		v.push(width * positiveScale);
		v.push(0);
		v.push(height * positiveScale);
		// Norm
		v.push(0);
		v.push(1);
		v.push(0);
		// UV
		v.push(1);
		v.push(0);

		buffer = h3d.Buffer.ofFloats(v, 8, [Quads, RawFormat]);
	}

	override function getBounds():Bounds {
		var b = new h3d.col.Bounds();
		if (centered) {
			b.addPos(-width * 0.5, 0, -height * 0.5);
			b.addPos(-width * 0.5, 0, height * 0.5);
		} else {
			b.addPos(0, 0, 0);
			b.addPos(width, 0, height);
		}
		return b;
	}
	*/

	public static function defaultQuad() {
		var engine = h3d.Engine.getCurrent();
		var inst = @:privateAccess engine.resCache.get(Quad);
		if (inst == null) {
			inst = new Quad();
			@:privateAccess engine.resCache.set(Quad, inst);
		}
		return inst;
	}
}
