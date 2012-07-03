//漫反射 (有bug，还没搞定)
//看出问题的 nshen121@gmail.com 告知，万分感谢

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
	
	public class Test6 extends Sprite
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
			context3D.enableErrorChecking = true ;
			context3D.configureBackBuffer(stage.stageWidth,stage.stageHeight,2,true);
			context3D.setCulling(Context3DTriangleFace.NONE);
			
			/**
			 diffuse = Kd x lightColor x max(N · L, 0)
			 * 
			 mvp            : vc 0~3
			 Kd             : vc4
			 lightColor     : vc5
			 L              : vc6
			 N              : va2 
			 **/
			
			AGAL.init();
			AGAL.m44("op","va0","vc0");
			AGAL.mov("v0","va1"); //uv
			AGAL.dp3("vt0","va2","vc6");
			AGAL.sat("vt0","vt0"); // max(N · L, 0)
			AGAL.mul("vt0","vt0","vc5");//lightColor x max(N · L, 0)
			//			AGAL.mov("v1","vt0")
			AGAL.mul("v1","vt0","vc4"); //Kd x lightColor x max(N · L, 0)
			
			var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexAssembler.assemble(Context3DProgramType.VERTEX,AGAL.code);  
			
			AGAL.init();
			AGAL.tex("ft1","v0","fs0","2d","clamp","nomip");
			AGAL.mul("ft1","ft1","v1");
			AGAL.mov("oc","ft1");
			var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentAssembler.assemble(Context3DProgramType.FRAGMENT,AGAL.code);
			
			
			var vertexVector:Vector.<Number> = Vector.<Number>([
				-1,-1,-1,0,1,   //xyz uv
				1,-1,-1,1,1,
				0,1,0,0.5,0,
				-1,-1,1,1,1,    
				1,-1,1,0,1,
			])
			//申请上传顶点缓冲(x,y,z,u,v)
			var vertexBuffer:VertexBuffer3D = context3D.createVertexBuffer(5,5);
			vertexBuffer.uploadFromVector(vertexVector,0,5);
			
			//设置顶点寄存器
			context3D.setVertexBufferAt(0,vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(1,vertexBuffer,3,Context3DVertexBufferFormat.FLOAT_2);
			
			
			var indexVector:Vector.<uint> = Vector.<uint>([
				0,2,1,
				3,2,0,
				4,2,3,
				1,2,4
			])
			//申请上传索引缓冲
			indexBuffer = context3D.createIndexBuffer(12);
			indexBuffer.uploadFromVector(indexVector,0,12);
			
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
			modelMatrix.prependTranslation(0,0,5)
			cameraMatrix.appendTranslation(0,0,-5)
			
			
			//Kd is the material's diffuse color,
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX,4,Vector.<Number>([1,1,1,1])) //vc4 Kd
			
			// lightColor is the color of the incoming diffuse light,
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX,5,Vector.<Number>([0.8,0.8,0.8,0.8])) //vc5 lightColor
			
			
			var normalsVector:Vector.<Number> = generateNormals(vertexVector,indexVector);
			var normalBuffer:VertexBuffer3D = context3D.createVertexBuffer(5,3);
			normalBuffer.uploadFromVector(normalsVector,0,5);
			context3D.setVertexBufferAt(2,normalBuffer,0,Context3DVertexBufferFormat.FLOAT_3); //va2  N
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);
		}
		
		private function generateNormals(vertexV:Vector.<Number>  , indexV:Vector.<uint>):Vector.<Number>
		{
			var _normals:Vector.<Number> = new Vector.<Number>((vertexV.length/5)*3);
			
			for(var i:int = 0 ; i< indexV.length ; i+=3) //遍历每个三角形
			{
				//顶点索引
				var i1:int = indexV[i]*5;
				var i2:int = indexV[i+1]*5;
				var i3:int = indexV[i+2]*5;
				
				var v1:Vector3D = new Vector3D(vertexV[i1] , vertexV[i1+1],vertexV[i1+2]);
				var v2:Vector3D = new Vector3D(vertexV[i2] , vertexV[i2+1],vertexV[i2+2]);
				var v3:Vector3D = new Vector3D(vertexV[i3] , vertexV[i3+1],vertexV[i3+2]);
				
				var vn1:Vector3D = v3.subtract(v1);
				var vn2:Vector3D = v2.subtract(v1);
				var n:Vector3D = vn1.crossProduct(vn2);
				n.normalize();
				n.negate();
				
				_normals[indexV[i]*3] += n.x;
				_normals[indexV[i]*3+1] += n.y;
				_normals[indexV[i]*3+2] += n.z;
				
				_normals[indexV[i+1]*3] += n.x;
				_normals[indexV[i+1]*3+1] += n.y;
				_normals[indexV[i+1]*3+2] += n.z;
				
				_normals[indexV[i+2]*3] += n.x;
				_normals[indexV[i+2]*3+1] += n.y;
				_normals[indexV[i+2]*3+2] += n.z;
				
			}
			var temNormal:Vector3D = new Vector3D;
			for (i = 0 ; i< _normals.length ; i+=3)
			{
				temNormal.setTo(_normals[i],_normals[i+1],_normals[i+2]);
				temNormal.normalize();
				_normals[i] = temNormal.x;
				_normals[i+1] = temNormal.y;
				_normals[i+2] = temNormal.z;
			}
			return _normals;
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
			mvp.append(modelMatrix);    //model to world space
			mvp.append(cameraInvert);   // world to eye space
			mvp.append(projectionMatrix); // eye space to clip space
			
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,mvp,true)
			
			
			//L is the normalized vector toward the light source, and
			
			var p:Vector3D = cameraMatrix.position.clone();
			//			p.negate();
			p = new Vector3D(0,0,-10)
			p.normalize();
			trace(p)
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX,6, Vector.<Number>([p.x,p.y,p.z,p.w]));  //vc6
			
			context3D.clear();
			context3D.drawTriangles(indexBuffer);
			context3D.present();
		}
		
		protected function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
					cameraMatrix.appendTranslation(0,0,0.05);
					break ;
				case Keyboard.DOWN:
					cameraMatrix.appendTranslation(0,0,-0.05);
					break ;
				case Keyboard.LEFT:
					cameraMatrix.appendTranslation(-0.05,0,0);
					break ;
				case Keyboard.RIGHT:
					cameraMatrix.appendTranslation(0.05,0,0);
					break ;
			}
		}
		
		
		public function Test6()
		{
			initStage3D();
		}
	}
}