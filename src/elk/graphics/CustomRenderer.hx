package elk.graphics;

import elk.graphics.pass.RetroPass;

class CustomRenderer extends h3d.scene.fwd.Renderer {
	var retroPass: RetroPass;
	var colorPass: h3d.pass.ColorMatrix;
	
	public var enableRetroFilter = true;
	
	public function new() {
		super();
		retroPass = new RetroPass();
		colorPass = new h3d.pass.ColorMatrix();
	}
	
	public function setTint(color: Int) {
		var col = h3d.Vector.fromColor(color);
		colorPass.matrix = h3d.Matrix.S(col.x, col.y, col.z);
	}
	
	override function render() {
		if( has("shadow") )
			renderPass(shadow,get("shadow"));

		if( has("depth") )
			renderPass(depth,get("depth"));

		if( has("normal") )
			renderPass(normal,get("normal"));

		renderPass(defaultPass, get("default") );
		renderPass(defaultPass, get("alpha"), backToFront );
		renderPass(defaultPass, get("additive") );

		resetTarget();
	}
}