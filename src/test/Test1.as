//基础rgb三角形

package test
{
	import com.adobe.utils.*;
	
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	public class Test1 extends Sprite
	{
		private var stage3D:Stage3D;
		private var context3D:Context3D;
		private var indexBuffer:IndexBuffer3D;
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
			vertexAssembler.assemble(Context3DProgramType.VERTEX,
				"mov op,va0 \n"+
				"mov v0,va1");
			//Create fragment assembler;
			var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentAssembler.assemble(Context3DProgramType.FRAGMENT,
				"mov oc,v0");
			
			//Init vertex buffer.
			var vertexBuffer:VertexBuffer3D = context3D.createVertexBuffer(3,6);
			vertexBuffer.uploadFromVector(Vector.<Number>([
				-1,-1,0,1,0,0,
				1,-1,0,0,1,0,
				0,1,0,0,0,1]),0,3);
			context3D.setVertexBufferAt(0,vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(1,vertexBuffer,3,Context3DVertexBufferFormat.FLOAT_3);
			
			indexBuffer = context3D.createIndexBuffer(3);
			indexBuffer.uploadFromVector(Vector.<uint>([
				0,1,2
			]),0,3);
			
			var program:Program3D = context3D.createProgram();
			program.upload(vertexAssembler.agalcode,fragmentAssembler.agalcode);
			context3D.setProgram(program);
	
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);
//			context3D.setCulling(Context3DTriangleFace.BACK);  只显示顺时针的三角形
		}
		
		
		private function enterFrameHandler(pEvent:Event):void{
			context3D.clear();
			context3D.drawTriangles(indexBuffer);
			context3D.present();
		}
		public function Test1()
		{
			initStage3D();
		}
	}
}