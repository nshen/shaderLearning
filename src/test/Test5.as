//加入camera
package test
{
	import com.adobe.utils.*;
	
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
	
	public class Test5 extends Sprite
	{
		private var stage3D:Stage3D;
		private var context3D:Context3D;
		private var indexBuffer:IndexBuffer3D;
		[Embed( source = "t.jpg" )] 
		protected const TextureBitmap:Class;
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
		
		private function contextReady(pEvent:Event):void{
			context3D = stage3D.context3D;
			//设置缓冲区属性
			context3D.configureBackBuffer(stage.stageWidth,stage.stageHeight,2,true);
			context3D.setCulling(Context3DTriangleFace.NONE);
			
			//编译agal程序
			AGAL.init();
			AGAL.m44("op","va0","vc0");
			AGAL.mov("v0","va1");
			var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexAssembler.assemble(Context3DProgramType.VERTEX,AGAL.code);  
			
			AGAL.init();
			AGAL.tex("ft1","v0","fs0","2d","repeat","nomip");
			AGAL.mov("oc","ft1");
			var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentAssembler.assemble(Context3DProgramType.FRAGMENT,AGAL.code);
			
			//申请上传顶点缓冲(x,y,z,u,v)
			var vertexBuffer:VertexBuffer3D = context3D.createVertexBuffer(3,5);
			vertexBuffer.uploadFromVector(Vector.<Number>([
				-1,1,0, 0,0,
				1,1,0 , 1,0,
				0,-1,0, 0.5,1]),0,3);
			
			//设置顶点寄存器
			context3D.setVertexBufferAt(0,vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(1,vertexBuffer,3,Context3DVertexBufferFormat.FLOAT_2);
			
			//申请上传索引缓冲
			indexBuffer = context3D.createIndexBuffer(3);
			indexBuffer.uploadFromVector(Vector.<uint>([
				0,1,2
			]),0,3);
			
			//上传shader
			var program:Program3D = context3D.createProgram();
			program.upload(vertexAssembler.agalcode,fragmentAssembler.agalcode);
			context3D.setProgram(program);
			
			var bitmap :Bitmap  = new TextureBitmap();
			//申请上传texture
			var texture:Texture = context3D.createTexture(bitmap.width,bitmap.height,Context3DTextureFormat.BGRA,false);
			texture.uploadFromBitmapData(bitmap.bitmapData);
			
			//设置纹理采样寄存器
			context3D.setTextureAt(0,texture);
			
			//projection
			projectionMatrix.perspectiveFieldOfViewLH(45*Math.PI/180 , stage.stageWidth/stage.stageHeight,0.1,30000);
			modelMatrix.appendTranslation(0,0,5);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);
		}
		
		
		private var mvp:Matrix3D = new Matrix3D(); //ModelViewProjection
		private var modelMatrix:Matrix3D = new Matrix3D();
		private var cameraMatrix:Matrix3D = new Matrix3D();
		private var projectionMatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
		
		private function enterFrameHandler(pEvent:Event):void{
			
			modelMatrix.prependRotation(1,Vector3D.Y_AXIS);
			
			var cameraInvert:Matrix3D = cameraMatrix.clone();
			cameraInvert.invert();
			
			mvp.identity();
			mvp.append(modelMatrix);
			mvp.append(cameraInvert);
			mvp.append(projectionMatrix);
			
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,mvp,true)
				
			context3D.clear();
			context3D.drawTriangles(indexBuffer);
			context3D.present();
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
			}
		}
		
		public function Test5()
		{
			initStage3D();
			
		}
	}
}