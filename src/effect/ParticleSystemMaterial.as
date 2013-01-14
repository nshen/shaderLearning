package effect
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import effect.ParticleSystem;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class ParticleSystemMaterial
	{
		
		// index buffer
		protected var _indexBuffer:IndexBuffer3D;
		protected var _indexBufferDirty:Boolean;
		
		// vertextBuffers
		protected var _vertexBuffer:VertexBuffer3D ;		// va0
		protected var _vertexBuffer1:VertexBuffer3D;		// va1(u,v, dx,dy) 偏移方向sizex,sizey = -1 or 1
		protected var _vertexBuffer2:VertexBuffer3D;		// va2(pastTime , lifeTime ,rot,rotVel)
		protected var _vertexBuffer3:VertexBuffer3D;		// va3(Vx, Vy, Vz, ?)
		protected var _vertexBuffer4:VertexBuffer3D;
		
		// dirty flags
		protected var _vertexBufferDirty:Boolean;
		protected var _vertexBufferDirty1:Boolean;
		protected var _vertexBufferDirty2:Boolean;
		protected var _vertexBufferDirty3:Boolean;
		protected var _vertexBufferDirty4:Boolean;
		
		private var _vertexData0 : Vector.<Number>;			// vertex
		private var _vertexData1 : Vector.<Number>;			// vertex1
		private var _vertexData2 : Vector.<Number>;			// vertex2
		private var _vertexData3 : Vector.<Number>;			// vertex3
		private var _vertexData4 : Vector.<Number>;			// vertex4
		
		private var _indexData : Vector.<uint>;				// index
		private var numTris:int ;
		
		private var _particleSystem:ParticleSystem
		private var _maxVertexNum:uint = 0 ;
		private var _maxIndexNum:uint = 0 ;
		
		protected var programInitialized:Boolean = false ;
		protected var shader:Program3D;
//		protected var _texture:Texture2D;
		
		public var mvp:Matrix3D;
			
		public function ParticleSystemMaterial(ps:ParticleSystem )
		{
			_particleSystem = ps;
//			_texture = texture;
			
			_maxVertexNum = _particleSystem.maxCapacity * 4 ;        // 一个粒子4个顶点
			_maxIndexNum = _particleSystem.maxCapacity * 6;			// 一个粒子6个index
			
			_vertexData0 = new Vector.<Number>(_maxVertexNum * 3, true);	// 3(x,y,z)
			_vertexData1 = new Vector.<Number>(_maxVertexNum * 4, true); // vertexBuffer1( u, v, sizeX, sizeY )
			_vertexData2 = new Vector.<Number>(_maxVertexNum * 4, true);
			_vertexData3 = new Vector.<Number>(_maxVertexNum * 4, true);
			_vertexData4 = new Vector.<Number>(_maxVertexNum * 4, true);// vertexBuffer4 颜色(r, g, b, a)
			
			_indexData = new Vector.<uint>(_maxIndexNum, true); // 一个粒子6个index
		}
		
		
        public function render(context:Context3D):void
		{
			if(generateBufferData(context))
			{
				prepareForRender(context);
				context.drawTriangles(_indexBuffer);
				clearAfterRender(context);
			}
		}
		
		public var scaleU : Number = 1.0;
		public var scaleV : Number = 1.0;
		private static var tmpVec3 : Vector3D = new Vector3D;
		
		public function uploadParticle(newParticle:Particle , updateIndex:Boolean = false):void
		{
			var index:int = newParticle.index;
			// va0 粒子的位置
			_vertexData0[index*12+0] = newParticle.pos.x;
			_vertexData0[index*12+1] = newParticle.pos.y;
			_vertexData0[index*12+2] = newParticle.pos.z;
			
			_vertexData0[index*12+3] = newParticle.pos.x;
			_vertexData0[index*12+4] = newParticle.pos.y;
			_vertexData0[index*12+5] = newParticle.pos.z;
			
			_vertexData0[index*12+6] = newParticle.pos.x;
			_vertexData0[index*12+7] = newParticle.pos.y;
			_vertexData0[index*12+8] = newParticle.pos.z;
			
			_vertexData0[index*12+9] = newParticle.pos.x;
			_vertexData0[index*12+10] = newParticle.pos.y;
			_vertexData0[index*12+11] = newParticle.pos.z;
			
			_vertexBufferDirty = true ;
			
			// va1 粒子的初始uv和sizeX,sizeY偏移
			_vertexData1[index*16] = 0.0;
			_vertexData1[index*16+1] = 0.0;
			_vertexData1[index*16+2] = -newParticle.sizeX/2;
			_vertexData1[index*16+3] = newParticle.sizeY/2;
			
			_vertexData1[index*16+4] = scaleU;
			_vertexData1[index*16+5] = 0.0;
			_vertexData1[index*16+6] = newParticle.sizeX/2;
			_vertexData1[index*16+7] = newParticle.sizeY/2;
			
			_vertexData1[index*16+8] = scaleU;
			_vertexData1[index*16+9] = scaleV;
			_vertexData1[index*16+10] = newParticle.sizeX/2;
			_vertexData1[index*16+11] = -newParticle.sizeY/2;
			
			_vertexData1[index*16+12] = 0.0;
			_vertexData1[index*16+13] = scaleV;
			_vertexData1[index*16+14] = -newParticle.sizeX/2;
			_vertexData1[index*16+15] = -newParticle.sizeY/2;
			
			_vertexBufferDirty1 = true;
			
			
			// va2 粒子生命期 (pastTime , lifeTime ,rot,rotVel)
			var liftTime : int = newParticle.pastTime + newParticle.remainTime
			_vertexData2[index*16] = newParticle.pastTime;
			_vertexData2[index*16+1] = liftTime;
			_vertexData2[index*16+2] = newParticle.rot;
			_vertexData2[index*16+3] = newParticle.rotVel;
			
			_vertexData2[index*16+4] = newParticle.pastTime;
			_vertexData2[index*16+5] = liftTime;
			_vertexData2[index*16+6] = newParticle.rot;
			_vertexData2[index*16+7] = newParticle.rotVel;
			
			_vertexData2[index*16+8] = newParticle.pastTime;
			_vertexData2[index*16+9] = liftTime;
			_vertexData2[index*16+10] = newParticle.rot;
			_vertexData2[index*16+11] = newParticle.rotVel;
			
			_vertexData2[index*16+12] = newParticle.pastTime;
			_vertexData2[index*16+13] = liftTime;
			_vertexData2[index*16+14] = newParticle.rot;
			_vertexData2[index*16+15] = newParticle.rotVel;
			
			_vertexBufferDirty2 = true;
			
			// va3 粒子速度
			tmpVec3.copyFrom(newParticle.dir);
			tmpVec3.scaleBy(newParticle.vel);
			
			_vertexData3[index*16] = tmpVec3.x;
			_vertexData3[index*16+1] = tmpVec3.y;
			_vertexData3[index*16+2] = tmpVec3.z;
			_vertexData3[index*16+3] = 0;
			
			_vertexData3[index*16+4] = tmpVec3.x;
			_vertexData3[index*16+5] = tmpVec3.y;
			_vertexData3[index*16+6] = tmpVec3.z;
			_vertexData3[index*16+7] = 0;
			
			_vertexData3[index*16+8] = tmpVec3.x;
			_vertexData3[index*16+9] = tmpVec3.y;
			_vertexData3[index*16+10] = tmpVec3.z;
			_vertexData3[index*16+11] = 0;
			
			_vertexData3[index*16+12] = tmpVec3.x;
			_vertexData3[index*16+13] = tmpVec3.y;
			_vertexData3[index*16+14] = tmpVec3.z;
			_vertexData3[index*16+15] = 0;
			
			_vertexBufferDirty3 = true;
			
			// va4 粒子颜色
			_vertexData4[index*16] = newParticle.r;
			_vertexData4[index*16+1] = newParticle.g;
			_vertexData4[index*16+2] = newParticle.b;
			_vertexData4[index*16+3] = newParticle.alpha;
			
			_vertexData4[index*16+4] = newParticle.r;
			_vertexData4[index*16+5] = newParticle.g;
			_vertexData4[index*16+6] = newParticle.b;
			_vertexData4[index*16+7] = newParticle.alpha;
			
			_vertexData4[index*16+8] = newParticle.r;
			_vertexData4[index*16+9] = newParticle.g;
			_vertexData4[index*16+10] = newParticle.b;
			_vertexData4[index*16+11] = newParticle.alpha;
			
			_vertexData4[index*16+12] = newParticle.r;
			_vertexData4[index*16+13] = newParticle.g;
			_vertexData4[index*16+14] = newParticle.b;
			_vertexData4[index*16+15] = newParticle.alpha;
			
			_vertexBufferDirty4 = true;
			
			if(updateIndex)
			{
				//index
				_indexData[index *6] = index *4;			// 0 1 2
				_indexData[index *6+1] = index *4+1;
				_indexData[index *6+2] = index *4+2;
				_indexData[index *6+3] = index *4;			// 0 2 3
				_indexData[index *6+4] = index *4+2;
				_indexData[index *6+5] = index *4+3;
				
				_indexBufferDirty = true ;
			}
		}
		
		

		
		protected function generateBufferData(context:Context3D):Boolean
		{
			
			var maxLiveVertexNum:int = (_particleSystem.maxLiveIndex + 1) * 4; // 最大活着的粒子数 × 每个粒子4个点  = 最大活着的顶点数
			if(maxLiveVertexNum <= 0 )
				return false;
			
			var _particles : Vector.<Particle> = _particleSystem.particles;
			for(var i:int = 0; i<=_particleSystem.maxLiveIndex; i++)
			{
				var p : Particle = _particles[i];	
				if(p)
				{
					_vertexData2[i*16] = p.pastTime;
					_vertexData2[i*16+4] = p.pastTime;
					_vertexData2[i*16+8] = p.pastTime;
					_vertexData2[i*16+12] = p.pastTime;
				}
			
			}
			_vertexBufferDirty2 = true ;
			
			
			
			if (_vertexBufferDirty || !_vertexBuffer) 
			{
				_vertexBuffer ||= context.createVertexBuffer(_maxVertexNum, 3);
				_vertexBuffer.uploadFromVector(_vertexData0, 0, _maxVertexNum);
				_vertexBufferDirty = false;
			}
			
			if (_vertexBufferDirty1 || !_vertexBuffer1) 
			{
				_vertexBuffer1 ||= context.createVertexBuffer(_maxVertexNum, 4);
				_vertexBuffer1.uploadFromVector( _vertexData1, 0, _maxVertexNum);
				_vertexBufferDirty1 = false;
			}
			
			if (_vertexBufferDirty2 || !_vertexBuffer2) 
			{
				_vertexBuffer2 ||= context.createVertexBuffer(_maxVertexNum, 4);
				_vertexBuffer2.uploadFromVector( _vertexData2, 0, _maxVertexNum);
				_vertexBufferDirty2 = false;
			}
			
			if (_vertexBufferDirty3 || !_vertexBuffer3) 
			{
				_vertexBuffer3 ||= context.createVertexBuffer(_maxVertexNum, 4);
				_vertexBuffer3.uploadFromVector( _vertexData3, 0, _maxVertexNum);
				_vertexBufferDirty3 = false;
			}			
			
			if (_vertexBufferDirty4 || !_vertexBuffer4) 
			{
				_vertexBuffer4 ||= context.createVertexBuffer(_maxVertexNum, 4);
				_vertexBuffer4.uploadFromVector( _vertexData4, 0, _maxVertexNum);
				_vertexBufferDirty4 = false;
			}			
			
			if (_indexBufferDirty || !_indexBuffer) 
			{
				_indexBuffer ||= context.createIndexBuffer(_maxIndexNum);
				_indexBuffer.uploadFromVector(_indexData, 0, _maxIndexNum);
				numTris = int( (_particleSystem.maxLiveIndex + 1) * 2);
				_indexBufferDirty = false;
			}
			
			if(!programInitialized)
			{
				initProgram(context);
				programInitialized = true ;
			}
			return true ;
		}
		
		
	
		/*
		*	输入寄存器的使用
		* va0		起始位置(x,y,z)
		* va1		uv和顶点偏移(u,v,sizeX,sizeY)
		* va2		生命值和旋转(passtime, lifetime, rot, rotv)
		* va3		速度(Vx,Vy,Vz)
		* va4		颜色(r,g,b,a) 
		* 
		* vt0       (生命比例，移动后的x,y,z)
		  vt1       (cos*x,sin*y,cos*y,sin*x)
		  vt2       (旋转角度，sin角度，cos角度)
		  vt3       (旋转后的sizeX,sizeY,,)
		
		  v0        va1
		  v1        va4
		  
		  vc0~3     mvp
		  vc4       [0, 1, 2, 1000]
		
		*/	
		private  function getVertexShader():String
		{
			AGAL.init();
			
		
			
			AGAL.div("vt0.x" , "va2.x" , "va2.y");  // vt0.x =  passtime / lifetime
			AGAL.sat("vt0.x","vt0.x");
			
			AGAL.mov("v5","va2.wwww")
			//旋转 :2d向量旋转公式：new Vector2D( (cos*x) - (sin*y) , (cos*y) + (sin*x) );
			AGAL.mul("vt3.x","va2.x","va2.w"); // passTime * rotV 
			AGAL.div("vt3.x","vt3.x","vc4.w"); // /1000
			AGAL.add("vt3.x","vt3.x","va2.z"); // vt3.x = rot + rotV * passTime
			AGAL.sin("vt3.y","vt3.x");
			AGAL.cos("vt3.z","vt3.x");
			AGAL.mul("vt1.x","vt3.z","va1.z"); // cos*x
			AGAL.mul("vt1.y","vt3.y","va1.w"); // sin*y
			AGAL.mul("vt1.z","vt3.z","va1.w"); // cos*y
			AGAL.mul("vt1.w","vt3.y","va1.z"); // sin*x
			//vt0.yz = 偏移后的顶点位置
			AGAL.sub("vt0.y","vt1.x","vt1.y"); //(cos*x) - (sin*y)  
			AGAL.add("vt0.z","vt1.z","vt1.w"); //(cos*y) + (sin*x) 
			AGAL.mov("vt2","va0");
			AGAL.add("vt2.xy","va0.xy","vt0.yz"); //vt2旋转后的位置
			// 移动
			AGAL.mul("vt4.xyz","va2.xxx","va3.xyz"); //vt1 指定时间移动的距离
			AGAL.div("vt4.xyz","vt4.xyz","vc4.www"); //vt1.xyz = passTime * V /1000
			AGAL.add("vt2.xy","vt2.xy","vt4.xy"); //vt2 移动+旋转后的位置
			
			

			
			AGAL.m44("vt5","vt2","vc0");
			
			AGAL.slt("vt0.x","va2.x","va2.y");
			AGAL.mul("op","vt5","vt0.x");
			AGAL.sub("v3","vt0.x","vc4.y");
			
//			AGAL.mov("op","va0")
//			AGAL.mov("v0","vt1.xyz");
			AGAL.mov("v0","va4.xyz");
//			AGAL.mov("v2","va3");
//			
//			AGAL.sin("vt0.x","vt0.x");     // vt0.x =  sin(t)
//			AGAL.mul("vt0.x","vt0.w","vt0.x"); //vt0.x = moveSpeed * sin(t)
//			AGAL.add("vt2.xy","vt2.xy","vt0.xx"); // pos = pos + moveSpeed * sin(t)
			
			
			
			return AGAL.code;
		
		}
		private function getFragmentShader():String
		{
			AGAL.init();
//			AGAL.kil("v3.x");
			AGAL.mov("oc","v5");
			return AGAL.code;
		}
		

		
		protected function initProgram(context:Context3D):void
		{
			var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexAssembler.assemble(Context3DProgramType.VERTEX,getVertexShader());  
			
			var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentAssembler.assemble(Context3DProgramType.FRAGMENT,getFragmentShader());
			
			shader ||= context.createProgram();
			shader.upload(vertexAssembler.agalcode, fragmentAssembler.agalcode);
		}
		

		
		private var _commonConst4 : Vector.<Number> = Vector.<Number>([0, 1, 2, 1000]);			// 常用常量
		private var _commonConst5 : Vector.<Number> = Vector.<Number>([0, 0, 0, 0]);		// 常用常量
		
		protected function prepareForRender(context:Context3D):void
		{
	
//			context.setBlendFactors(blendMode.src, blendMode.dst);
			
//			context.setVertexBufferAt(0,_vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
//			context.setVertexBufferAt(4,_vertexBuffer,3,Context3DVertexBufferFormat.FLOAT_4);
			context.setProgram(shader);
			//--
			context.setVertexBufferAt(0,_vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3); //va0 (x,y,z)
			context.setVertexBufferAt(1,_vertexBuffer1,0,Context3DVertexBufferFormat.FLOAT_4);//va1 ( u, v, sizeX, sizeY )
			context.setVertexBufferAt(2,_vertexBuffer2,0,Context3DVertexBufferFormat.FLOAT_4); //va2  (pastTime , lifeTime ,rot,rotVel)
			context.setVertexBufferAt(3,_vertexBuffer3,0,Context3DVertexBufferFormat.FLOAT_4); //va3 速度 (x,y,z)
			context.setVertexBufferAt(4,_vertexBuffer4,0,Context3DVertexBufferFormat.FLOAT_4); //va4 (r, g, b, a)
			
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvp, true); //vc0~3
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,4,_commonConst4,1);//vc4
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,5,_commonConst5,1);//vc5
			
			
//			// 6-9 M
//			stage3DProxy._context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 6, renderable.sceneTransform, true);
//			// 10-13 inverse M
//			stage3DProxy._context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 10, renderable.inverseSceneTransform, true);
//			// 14-17 camera transform
//			stage3DProxy._context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 14, camera.sceneTransform, true);
//			
//			// 18 camear Z
//			tmpVec3.setTo(0, 0, 1);
//			tmpVec3 = camera.sceneTransform.deltaTransformVector(tmpVec3);
//			tmpVec4[0] = tmpVec3.x; tmpVec4[1] = tmpVec3.y; tmpVec4[2] = tmpVec3.z; tmpVec4[3] = 0;
//			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 18, tmpVec4, 1);
			
			// 19 保留
			
			// 粒子控制器的处理
//			if(!_isUpdateEffectors)
//			{
//				UpdateEffectors();			// 计算粒子控制器的向量
//				_isUpdateEffectors = true;
//			}
//			
//			// 20-22 Color Effector
//			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 20, _colorEffectorVect43, gpuEffectorKeyFrameMax);
//			// 23-25 Alpha Effector
//			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 23, _alphaEffectorVect43, gpuEffectorKeyFrameMax);
//			// 26-28 Size Effector
//			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 26, _sizeEffectorVect43, gpuEffectorKeyFrameMax);
//			// 29-34 UV	Effector
//			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 29, _uvEffectorVect43, gpuEffectorKeyFrameMax*2);
//			// 35 force Effector
//			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 35, _forceEffectorVect4, 1);
//			// 36 attract Effector
//			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 36, _attractEffectorVect4, 1);
			
			
			
		}
		
		protected function clearAfterRender(context:Context3D):void
		{
			context.setVertexBufferAt(0,null);
			context.setVertexBufferAt(1,null);
			context.setVertexBufferAt(2,null);
			context.setVertexBufferAt(3,null);
			context.setVertexBufferAt(4,null);
		}
			
		
		public function handleDeviceLoss():void 
		{
			super.handleDeviceLoss();
			programInitialized = false;
			_indexBuffer = null;
			
			_vertexBuffer = null;
			_vertexBuffer1 = null;
			_vertexBuffer2 = null;
			_vertexBuffer3 = null;
			_vertexBuffer4 = null;
		}
		
		public function dispose():void
		{
			super.dispose()
			if(_indexBuffer)
			{
				_indexBuffer.dispose();
				_indexBuffer = null ;
			}
			if(_vertexBuffer)
			{
				_vertexBuffer.dispose();
				_vertexBuffer = null ;
			}
			if(_vertexBuffer1)
			{
				_vertexBuffer1.dispose();
				_vertexBuffer1 = null ;
			}
			if(_vertexBuffer2)
			{
				_vertexBuffer2.dispose();
				_vertexBuffer2 = null ;
			}
			if(_vertexBuffer3)
			{
				_vertexBuffer3.dispose();
				_vertexBuffer3 = null ;
			}
			if(_vertexBuffer4)
			{
				_vertexBuffer4.dispose();
				_vertexBuffer4 = null ;
			}
		}
	}
}