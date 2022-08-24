package elk.graphics;

import elk.graphics.pass.RetroPass;

class CustomRenderer extends h3d.scene.fwd.Renderer {
	var retroPass: RetroPass;
	var colorPass: h3d.pass.ColorMatrix;
	
	public var enableRetroFilter = true;
	
	public var uiScene: h2d.Scene = null;

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
		/*
		var ui : h3d.mat.Texture = null;
		if (uiScene != null) {
			ui = allocTarget("uiLayer", false, 1, RGBA);
			ui.clear(ctx.engine.backgroundColor, 0);
			ctx.engine.pushTarget(ui);
			uiScene.render(ctx.engine);
			ctx.engine.popTarget();
		}
		
		var output: h3d.mat.Texture = null;
		if (enableRetroFilter) {
			output = allocTarget("pixelOutput");
			setTarget(output);
			clear(h3d.Engine.getCurrent().backgroundColor, 1, 0);
		}
		*/
		
		//var hehe = allocTarget("tempcool");
		//ctx.engine.pushTarget(hehe);
		//ctx.engine.popTarget();
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

		//colorPass.apply(output, output);
		
		/*
		if (uiScene != null) {
			h3d.pass.Copy.run(ui, output, Alpha);
		}

		if (enableRetroFilter) {
			retroPass.apply(ctx, output);
			h3d.pass.Copy.run(output, null);
		}
		*/
	}
}