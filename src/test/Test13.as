// gpu拖尾,不完美,觉得是easyagal的atan的问题?

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
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	[SWF(width="800",height="800")]
	public class Test13 extends Sprite
	{
		private var stage3D:Stage3D;
		private var context3D:Context3D;
		private var indexBuffer:IndexBuffer3D;
		private var vertexBuffer:VertexBuffer3D;
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
			context3D.enableErrorChecking = true
				
			for(var p:int = 0 ; p < _recordPointsNum ; p ++)
			{
				_points.push({x:0,y:0});
				
			}
			

			
			
			//n个记录点有2n个顶点，(n-1)*6个索引 
//			
//		    _vertexData = new Vector.<Number>(_recordPointsNum * 2,true);
//			_indexData  = new Vector.<uint>((_recordPointsNum - 1) * 6 ,true);
		
//			var tail:Vector.<Number> = Vector.<Number>([
//				0,0,0, -200,50,0,1,  0,0,0,   1,0,0,   //xyz rgb
//				0,0,0, -200,50,0,-1, 0,0,0,   0,1,0,
//				-200,50,0, 0,0,0,1,     100,0,0,  0,0,1,
//				-200,50,0, 0,0,0,-1,    100,0,0,  1,0,0,
//				0,0,0,    100,0,0,1,   0,0,0,   0,1,0,
//				0,0,0,   100,0,0,-1,  0,0,0,   0,0,1
//			]);
			
//			var tailINdex:Vector.<uint> = Vector.<uint>([
//				0,1,2,
//				1,2,3,
//				3,2,4,
//				3,4,5
//			])
			
//			var tailINdex:Vector.<uint> = Vector.<uint>([
//				0,1,3,
//				0,3,2,
//				2,3,5,
//				2,5,4
//			])
				
			_indexData  = new Vector.<uint>((_recordPointsNum - 1) * 6 ,true);
		    for( var i:uint = 0 ; i < _recordPointsNum - 1  ; i ++)
			{
				_indexData[i * 6] = i * 2  ;
				_indexData[i * 6 + 1] = i * 2 + 1;
				_indexData[i * 6 + 2] = (i + 1) * 2 + 1;
				_indexData[i * 6 + 3] = i * 2;
				_indexData[i * 6 + 4] = (i + 1) * 2 + 1;
				_indexData[i * 6 + 5] = (i + 1) * 2;
			}
			indexBuffer = context3D.createIndexBuffer((_recordPointsNum - 1) * 6);
			indexBuffer.uploadFromVector(_indexData,0,(_recordPointsNum - 1) * 6);
		
			_vertexData = updateVertexData();
			
			vertexBuffer = context3D.createVertexBuffer(_recordPointsNum * 2,13);
			vertexBuffer.uploadFromVector(_vertexData,0,_recordPointsNum * 2);
			
			
			_shader  = new EasyShader();
			_shader.upload(context3D);
			
			context3D.setVertexBufferAt(0,vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);//last
			context3D.setVertexBufferAt(1,vertexBuffer,3,Context3DVertexBufferFormat.FLOAT_4);//current
			context3D.setVertexBufferAt(2,vertexBuffer,7,Context3DVertexBufferFormat.FLOAT_3);//next
			context3D.setVertexBufferAt(3,vertexBuffer,10,Context3DVertexBufferFormat.FLOAT_3);//rgb
			
			perspection = new PerspectiveMatrix3D();
			perspection.orthoLH(stage.stageWidth,stage.stageHeight,0,1)
			modelView = new Matrix3D();
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);
           
			
		}
		
		protected var _lastFrameTime:Number = 0;
		protected var _passTime:Number = 0 ;
		protected var _recordTime:Number = 10;
		
		protected var _points:Array = [];
		protected var _recordPointsNum:uint = 30;
		private function enterFrameHandler(pEvent:Event):void{
			
			var t:Number = getTimer();
			var elapsed:Number = t - _lastFrameTime;
			_lastFrameTime = t;
			
			_passTime += elapsed;
			if(_passTime >= _recordTime)
			{
				_passTime = 0;
				recordPoints(stage.mouseX,stage.mouseY)
			}
			
			context3D.clear();
			context3D.setProgram(_shader.program);
			
			var modelProjection:Matrix3D = new Matrix3D(); 
		 	modelProjection.append(modelView);              
			modelProjection.append(perspection);          
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,modelProjection,true);
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX,4,Vector.<Number>([70,Math.PI/2,Math.PI,200]),1);
			context3D.drawTriangles(indexBuffer);
			context3D.present();
		}
		
		private function recordPoints(mouseX:Number, mouseY:Number):void
		{
			var newx:Number = mouseX - 400;
			var newy:Number = -1* (mouseY -400);
			
			_points.pop();
			_points.unshift({x:newx , y:newy});
			
			_vertexData = updateVertexData();
			
			vertexBuffer.uploadFromVector(_vertexData,0,_recordPointsNum * 2);
			
			
			
			
			
		}
		
		protected var _vertexData:Vector.<Number> ;
		protected var _indexData:Vector.<uint> ;
		protected function updateVertexData():Vector.<Number>
		{
            var data:Vector.<Number> = new Vector.<Number>()
			var last:Object;
			var current:Object;
			var next:Object;
			for(var i:uint = 0 ; i < _points.length ; i ++ )
			{
				if(i == 0 )
				{
					
					current = _points[0];
					next = _points[1];
					
					last = current
					
					
				}else if(i == _points.length -1)
				{
					
					last = _points[i-1];
					current = _points[i];
					next = _points[i]
				}else
				{
					last = _points[i-1];
					current = _points[i];
				    next = _points[i+1];
				}
//				_vertexData.splice(i*26,26,last.x,last.y,0, current.x,current.y,0,1 ,next.x,next.y,0, 1,0,0    ,    last.x,last.y,0, current.x,current.y,0,-1 ,next.x,next.y,0, 0,1,0);
//				_vertexData[i*26] = 
//				_vertexData[i*2+1] =
				data.push(last.x,last.y,0, current.x,current.y,0,1 ,next.x,next.y,0, 1,0,0);
				data.push(last.x,last.y,0, current.x,current.y,0,-1 ,next.x,next.y,0, 0,1,0);
				
			}
			return data;
		}
		public function Test13()
		{
			initStage3D()
			
		}
	}
}

import com.barliesque.agal.EasyAGAL;
import com.barliesque.agal.IRegister;
import com.barliesque.shaders.macro.Trig;
import com.barliesque.shaders.macro.Utils;

class EasyShader extends EasyAGAL
{
	public function EasyShader():void
	{
		super(true);
	}
	protected override function _vertexShader():void 
	{
		super._vertexShader();
		
		var tozh:IRegister  = TEMP[4];
		mov(tozh,ATTRIBUTE[0]);
		Utils.setTwoOneZeroHalf(tozh); //[2,1,0,0.5]
		
		var width:IRegister = TEMP[1];
//		mov(width,ATTRIBUTE[1].w); //
		mul(width,ATTRIBUTE[1].w,CONST[4].x); //vt1: + - 宽度偏移
		
		var pos:IRegister = TEMP[0];
		mov(TEMP[0],ATTRIBUTE[1]);
		mov(TEMP[0].w , tozh.y);
		
		
		sub(TEMP[2].xyz , ATTRIBUTE[0].xyz,ATTRIBUTE[1].xyz); //  last - current 
		nrm(TEMP[2].xyz , TEMP[2].xyz);
		sub(TEMP[3].xyz , ATTRIBUTE[1].xyz,ATTRIBUTE[2].xyz) //  current - next 
		nrm(TEMP[3].xyz , TEMP[3].xyz);
		
//		sub(TEMP[4].xyz , ATTRIBUTE[0].xyz , ATTRIBUTE[2].xyz)
//		nrm(TEMP[4].xyz , TEMP[4].xyz);
		
		
		add(TEMP[2].xyz , TEMP[2].xyz,TEMP[3].xyz);
		nrm(TEMP[2].xyz,TEMP[2].xyz);
//		add(TEMP[2].xyz , TEMP[2].xyz , TEMP[4].xyz);
//		nrm(TEMP[2].xyz , TEMP[2].xyz);
		
		Trig.atan2(TEMP[3],TEMP[2].x , TEMP[2].y ,tozh.z, tozh.y ,CONST[4].y ,CONST[4].z , TEMP[5],TEMP[6]);
		add(TEMP[3].x , TEMP[3].x ,CONST[4].y); // + Math.pi/2
		
		
		cos(TEMP[5].x , TEMP[3].x);
		sin(TEMP[5].y , TEMP[3].x);
		mul(TEMP[5].xy , TEMP[5].xy , width.x );//dir
		
		add(pos.xy,pos.xy,TEMP[5].xy);
		
	    m44(OUTPUT,pos,CONST[0]);
		
		mov(VARYING[0],ATTRIBUTE[3]); //rgb
	}
	
	protected override function _fragmentShader():void 
	{
		super._fragmentShader();
		mov(OUTPUT, VARYING[0]);
	}
}
