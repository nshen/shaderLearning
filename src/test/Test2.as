//带texture的三角形

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
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	public class Test2 extends Sprite
	{
		private var stage3D:Stage3D;
		private var context3D:Context3D;
		private var indexBuffer:IndexBuffer3D;
		[Embed( source = "RockSmooth.jpg" )] 
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
			//Initialize context3D;
			context3D = stage3D.context3D;
			context3D.configureBackBuffer(stage.stageWidth,stage.stageHeight,2,true);
			
			//Create vertex assembler;
			var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			AGAL.init();
			AGAL.mov("op","va0");
			AGAL.mov("v0","va1");
			vertexAssembler.assemble(Context3DProgramType.VERTEX,AGAL.code);  //uv
			//Create fragment assembler;
			var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			AGAL.init();
			AGAL.tex("ft1","v0","fs0","2d","linear","nomip");
			AGAL.mov("oc","ft1");
			fragmentAssembler.assemble(Context3DProgramType.FRAGMENT,AGAL.code);
			//Init vertex buffer.
			var vertexBuffer:VertexBuffer3D = context3D.createVertexBuffer(3,5);
			vertexBuffer.uploadFromVector(Vector.<Number>([
				-1,1,0, 0,0,
				1,1,0 , 1,0,
				0,-1,0, 0.5,1]),0,3);
			
			
			/**
			 *    (-1,1) ------------(1,1)
			 *           \           /
			 *            \         /
			 *             \
			 *             (0,-1)
			 */
			context3D.setVertexBufferAt(0,vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(1,vertexBuffer,3,Context3DVertexBufferFormat.FLOAT_2);
			
			indexBuffer = context3D.createIndexBuffer(3);
			indexBuffer.uploadFromVector(Vector.<uint>([
				0,1,2
			]),0,3);
			
			var program:Program3D = context3D.createProgram();
			program.upload(vertexAssembler.agalcode,fragmentAssembler.agalcode);
			context3D.setProgram(program);
			
			var bitmap :Bitmap  = new TextureBitmap();
			var texture:Texture = context3D.createTexture(bitmap.width,bitmap.height,Context3DTextureFormat.BGRA,false);
			texture.uploadFromBitmapData(bitmap.bitmapData);
			context3D.setTextureAt(0,texture);
			
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);
		}
		
		
		private function enterFrameHandler(pEvent:Event):void{
			context3D.clear();
			
			
			context3D.drawTriangles(indexBuffer);
			context3D.present();
		}
		public function Test2()
		{
			initStage3D();
		}
	}
}