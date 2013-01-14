package
{
	import com.adobe.utils.*;
	
	import effect.ParticleSystem;
	import effect.RectangleParticleEmitter;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	import flashx.textLayout.elements.BreakElement;

	[SWF(width="800" , height="800" ,frameRate="60")]
	public class ParticleTest extends Sprite
	{
		private var stage3D:Stage3D;
		private var context3D:Context3D;
		private var indexBuffer:IndexBuffer3D;
		[Embed( source = "t.jpg" )] 
		protected const TextureBitmap:Class;

		
		private var mvp:Matrix3D = new Matrix3D(); 
		private var modelMatrix:Matrix3D = new Matrix3D();
		private var cameraMatrix:Matrix3D = new Matrix3D();
		private var projectionMatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
		
		
		
		protected var ps:ParticleSystem ;
		private function contextReady(pEvent:Event):void
		{
			context3D = stage3D.context3D;
			context3D.configureBackBuffer(stage.stageWidth,stage.stageHeight,2,true);
			context3D.setCulling(Context3DTriangleFace.NONE);
			context3D.enableErrorChecking = true ;
			
//			projectionMatrix = new PerspectiveMatrix3D();
//			projectionMatrix.perspectiveFieldOfViewLH(45*Math.PI/180, stage.stageWidth/stage.stageHeight, 0.1, 10000);
			projectionMatrix = new PerspectiveMatrix3D();
			projectionMatrix.orthoLH(stage.stageWidth,stage.stageHeight,0,1)
			modelMatrix = new Matrix3D();
//			modelMatrix.appendTranslation(0,0,10)
				
			var emiter:RectangleParticleEmitter = new RectangleParticleEmitter();
			ps = new ParticleSystem(300,emiter); 
			ps.start();
			
			
			
				
			stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);
		}
		
		private var lastTime:int = 0 ;
		private function enterFrameHandler(pEvent:Event):void{
			
			
			var r:int = getTimer();
			var elapsed:int = r -  lastTime
			
			var cameraInvert:Matrix3D = cameraMatrix.clone();
			cameraInvert.invert();
			
			mvp.identity();
			mvp.append(modelMatrix);    //model to world space
			mvp.append(cameraInvert);   // world to eye space
			mvp.append(projectionMatrix); // eye space to clip space
			
			context3D.clear();
			ps.step(elapsed); //毫秒
			ps.draw(context3D,mvp);	
			context3D.present();

			lastTime = r;
		}
		
		protected function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
					cameraMatrix.appendTranslation(0,0.05,0);
					break ;
				case Keyboard.DOWN:
					cameraMatrix.appendTranslation(0,-0.05,0);
					break ;
				case Keyboard.LEFT:
					cameraMatrix.appendTranslation(-0.05,0,0);
					break ;
				case Keyboard.RIGHT:
					cameraMatrix.appendTranslation(0.05,0,0);
					break ;
				case Keyboard.ENTER:
					ps.start()
				    break ;
			}
		}
		
		
		
		public function ParticleTest()
		{
			initStage3D();
		}
		private function initStage3D(e:Event = null):void{
			if(stage)
			{
				stage3D = stage.stage3Ds[0];
				stage3D.addEventListener(Event.CONTEXT3D_CREATE, contextReady);
				stage3D.requestContext3D(Context3DRenderMode.AUTO);
			}else
			{
				addEventListener(Event.ADDED_TO_STAGE,initStage3D);
			}
		}
	}
}