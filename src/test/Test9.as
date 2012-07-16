// 处理3d环境丢失，方法参考nd2d

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
	import flash.utils.getTimer;

	[SWF(width="800",height="800",frameRate="60")]
	public class Test9 extends Sprite
	{
		private var stage3D:Stage3D;
		private var context3D:Context3D;
		private var indexBuffer:IndexBuffer3D;
		private var perspection:PerspectiveMatrix3D;
		private var modelView:Matrix3D;
		
		private var deviceInitialized:Boolean = false;
		private var deviceWasLost:Boolean = false;
		
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
			context3D.enableErrorChecking = true;
			
			trace("isHardwareAccelerated? " , context3D.driverInfo.toLowerCase().indexOf("software") == -1)
			
			// 如果Event.CONTEXT3D_CREATE 第2次被调用，说明环境丢失过，刚刚恢复
			if(deviceInitialized) 
			{
				deviceWasLost = true;  //做个标记，留到enterframe最前边处理环境丢失
			}
			deviceInitialized = true;
			
			initProgram();
			initBuffers();
			
			perspection = new PerspectiveMatrix3D();
			perspection.orthoLH(stage.stageWidth,stage.stageHeight,0,1)
			modelView = new Matrix3D();
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);

		}
		
		private function initProgram():void
		{
			// *旋转
			AGAL.init();
			AGAL.mov("vt0","vc4"); //两个常量不能直接计算  // vc4 [t , startRot , rotV , moveSpeed]
			AGAL.mul("vt0.x","vt0.x","vc4.z"); // t * rotV
			AGAL.add("vt0.x","vt0.x","vc4.y"); // startRot + t * rotV
			
			//2d向量旋转公式：new Vector2D( (cos*x) - (sin*y) , (cos*y) + (sin*x) );
			AGAL.sin("vt0.y","vt0.x");
			AGAL.cos("vt0.z","vt0.x");
			AGAL.mul("vt1.x","vt0.z","va0.x"); // cos*x
			AGAL.mul("vt1.y","vt0.y","va0.y"); // sin*y
			AGAL.mul("vt1.z","vt0.z","va0.y"); // cos*y
			AGAL.mul("vt1.w","vt0.y","va0.x"); // sin*x
			
			AGAL.mov("vt2","va0");
			AGAL.sub("vt2.x","vt1.x","vt1.y"); //(cos*x) - (sin*y)
			AGAL.add("vt2.y","vt1.z","vt1.w"); //(cos*y) + (sin*x)
			
			/**
			 上边三句换成这样是不行的，必须先整体move va，然后再覆盖zw ，不知道为什么，这里卡了一天
			 AGAL.sub("vt2.x","vt1.x","vt1.y"); //(cos*x) - (sin*y)
			 AGAL.add("vt2.y","vt1.z","vt1.w"); //(cos*y) + (sin*x)
			 AGAL.mov("vt2.zw","va0.zw");   
			 */
			
			// *移动
			AGAL.mov("vt0","vc4"); // 清空vt0为vc4
			AGAL.sin("vt0.x","vt0.x");     // vt0.x =  sin(t)
			AGAL.mul("vt0.x","vt0.w","vt0.x"); //vt0.x = moveSpeed * sin(t)
			AGAL.add("vt2.xy","vt2.xy","vt0.xx"); // pos = pos + moveSpeed * sin(t)
			
			AGAL.m44("op","vt2","vc0");
			AGAL.mov("v0","va1");
			
			var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexAssembler.assemble(Context3DProgramType.VERTEX,AGAL.code);
			
			//Create fragment assembler;
			AGAL.init();
			AGAL.mov("oc","v0");
			var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentAssembler.assemble(Context3DProgramType.FRAGMENT,AGAL.code);
			
			var program:Program3D = context3D.createProgram();
			program.upload(vertexAssembler.agalcode,fragmentAssembler.agalcode);
			context3D.setProgram(program);
		}
			
		private function initBuffers():void
		{
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
		}
		
		private var lastFrameTime:int = 0;
		private var constVector:Vector.<Number> = new Vector.<Number>();
		private function enterFrameHandler(pEvent:Event):void{
			
			if(context3D.driverInfo == "Disposed")  //环境丢失时，禁止主循环
			    return ;
			
			if(deviceWasLost) 
			{
				//环境恢复后
				//这里for each所有children handle deviceLost 
				deviceWasLost = false;
			}
			
			
			
			
			var t:Number = getTimer() * 0.001;
			var elapsed:int = t - lastFrameTime 
				
			context3D.clear();
			var modelProjection:Matrix3D = new Matrix3D(); 
			modelProjection.append(modelView);              
			modelProjection.append(perspection);          
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,modelProjection,true);
			
			constVector[0] = t ;  //持续时间
			constVector[1] = 0;   // 初始角度
			constVector[2] = 3;   // 旋转速度
			constVector[3] = 300; // 移动速度
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX,4,constVector,1); //vc4
			
			context3D.drawTriangles(indexBuffer);
			context3D.present();
			
			lastFrameTime = t;
		}
		public function Test9()
		{
			initStage3D()
			
		}
	}
}