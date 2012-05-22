//pixel shader重影特效
//取2个颜色中间插值

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
	
	public class Test4 extends Sprite
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
			//Initialize context3D;
			context3D = stage3D.context3D;
			context3D.configureBackBuffer(stage.stageWidth,stage.stageHeight,2,true);
			
			AGAL.init();
			AGAL.mov("op","va0");
			//uv复制2份
			AGAL.mov("v0","va1");
			AGAL.mov("v1","va1");
			//2份分别加减x偏移
			AGAL.add("v0.x","va1.x","vc0.y");
          	AGAL.sub("v1.x","va1.x","vc0.y");
			//Create vertex assembler;
			var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexAssembler.assemble(Context3DProgramType.VERTEX,AGAL.code);  
			
			
			AGAL.init();
			AGAL.tex("ft1","v0","fs0","2d","repeat","nomip");
			AGAL.tex("ft2","v1","fs0","2d","repeat","nomip"); 
//			var str:String = AGAL.code;
//			lerp
//			str += "sub ft3 ,ft2 ,ft1\n";
//			str += "mul ft3 ,ft3 ,fc0.w\n";
//			str	+= "add ft3 ,ft1 ,ft3\n" ;
//			str += "mov oc , ft3"
				
			AGAL.lerp("ft3","ft1","ft2","fc0.w");
			AGAL.mov("oc","ft3");
			//Create fragment assembler;
			var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
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
			
			var data:Vector.<Number> = Vector.<Number>([0.1, 0.2, 0.3, 0.4]);
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX,0,data,1);  //偏移参数vc0
			var data2:Vector.<Number> = Vector.<Number>([0.5,0.5,0.5,0.5])
			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,data2,1);//fc0 平均数0.5
			
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
		public function Test4()
		{
			initStage3D();
		}
	}
}