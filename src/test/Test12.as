// Cpu拖尾演示，没优化

package test
{
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	[SWF(width="800",height="800")]
	public class Test12 extends Sprite
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
				_points.push(new Vector3D());
				
			}
			
			
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
			
			vertexBuffer = context3D.createVertexBuffer(_recordPointsNum * 2,6);
			vertexBuffer.uploadFromVector(_vertexData,0,_recordPointsNum * 2);
			
			
			_shader  = new EasyShader();
			_shader.upload(context3D);
			
			context3D.setVertexBufferAt(0,vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);//pos
			context3D.setVertexBufferAt(1,vertexBuffer,3,Context3DVertexBufferFormat.FLOAT_3);//rgb
			
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
			//			if( )
			//			if(Math.sqrt((_points[0].x - newx)*(_points[0].x - newx) + (_points[0].y - newy)*(_points[0].y - newy)) < 10)
			//			 return;
			
			var p:Vector3D = _points.pop();
			p.x = newx;
			p.y = newy;
			
			_points.unshift(p);
			
			_vertexData = updateVertexData();
			
			vertexBuffer.uploadFromVector(_vertexData,0,_recordPointsNum * 2);
			
			
			
			
			
		}
		
		protected var _vertexData:Vector.<Number> ;
		protected var _indexData:Vector.<uint> ;
		protected function updateVertexData():Vector.<Number>
		{
			var data:Vector.<Number> = new Vector.<Number>()
			var last:Vector3D;
			var current:Vector3D;
			var next:Vector3D;
			for(var i:uint = 0 ; i < _points.length ; i ++ )
			{
				if(i == 0 )
				{
					
					current = _points[0];
					next = _points[1];
					
					last = current.clone();
					
					
				}else if(i == _points.length -1)
				{
					
					last = _points[i-1];
					current = _points[i];
					next = current.clone();
				}else
				{
					last = _points[i-1];
					current = _points[i];
					next = _points[i+1];
				}
				var n1:Vector3D = last.subtract(current);
				n1.normalize();
				var n2:Vector3D = current.subtract(next);
				n2.normalize();
				var n3:Vector3D = n1.add(n2);
				n3.normalize();
				var angle:Number = Math.atan2(n3.y,n3.x);
				angle += Math.PI/2;
				
				var v:Vector3D = new Vector3D(Math.cos(angle),Math.sin(angle));
				 v.scaleBy(50);
				 
				var p1:Vector3D = current.add(v);
				v.scaleBy(-1);
				var p2:Vector3D = current.add(v);
				data.push(p1.x,p1.y,p1.z, 1,0,0);
				data.push(p2.x,p2.y,p2.z,0,1,0);
				
			}
			return data;
		}
		public function Test12()
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
		
		mov(VARYING[0],ATTRIBUTE[1]); //rgb
	}
	
	protected override function _fragmentShader():void 
	{
		super._fragmentShader();
		mov(OUTPUT, VARYING[0]);
	}
}
