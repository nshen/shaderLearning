// easyagal

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

	[SWF(width="800",height="800")]
	public class Test11 extends Sprite
	{
		private var stage3D:Stage3D;
		private var context3D:Context3D;
		private var indexBuffer:IndexBuffer3D;
		private var perspection:PerspectiveMatrix3D;
		private var modelView:Matrix3D;
		private var _shader:EasyShader;
		private function initStage3D(e:Event = null):void
		{
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
		
		private function contextReady(pEvent:Event):void
		{
			context3D = stage3D.context3D;
			context3D.configureBackBuffer(stage.stageWidth,stage.stageHeight,2,true);
			
		
			
			//Init vertex buffer.
			var vertexBuffer:VertexBuffer3D = context3D.createVertexBuffer(3,6);
			vertexBuffer.uploadFromVector(Vector.<Number>([
				-100,-100,0,1,0,0,   //xyz rgb
				100,-100,0,0,1,0,
				0,100,0,0,0,1]),0,3);
			context3D.setVertexBufferAt(0,vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(1,vertexBuffer,3,Context3DVertexBufferFormat.FLOAT_3);
			
			indexBuffer = context3D.createIndexBuffer(3);
			indexBuffer.uploadFromVector(Vector.<uint>([
				0,1,2
			]),0,3);
			
			_shader  = new EasyShader();
			_shader.upload(context3D);
			
			perspection = new PerspectiveMatrix3D();
			perspection.orthoLH(stage.stageWidth,stage.stageHeight,0,1)
			modelView = new Matrix3D();
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);

		}
		
		
		private function enterFrameHandler(pEvent:Event):void{
			context3D.clear();
			context3D.setProgram(_shader.program);
			
			var modelProjection:Matrix3D = new Matrix3D(); 
			modelProjection.append(modelView);              
			modelProjection.append(perspection);          
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,modelProjection,true);
			
			context3D.drawTriangles(indexBuffer);
			context3D.present();
		}
		public function Test11()
		{
			initStage3D()
			
		}
	}
}

import com.barliesque.agal.EasyAGAL;

class EasyShader extends EasyAGAL
{
	public function EasyShader():void
	{
		super(true);
	}
	protected override function _vertexShader():void 
	{
		super._vertexShader();
	    m44(OUTPUT,ATTRIBUTE[0],CONST[0]);
		mov(VARYING[0],ATTRIBUTE[1]);
	}
	
	protected override function _fragmentShader():void 
	{
		super._fragmentShader();
		mov(OUTPUT, VARYING[0]);
	}
}
