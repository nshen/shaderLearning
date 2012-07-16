// obj模型 ,mipmap

package test
{
	import com.adobe.utils.*;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
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
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	[SWF(width="800",height="800",frameRate="60")]
	public class Test10 extends Sprite
	{
		private var stage3D:Stage3D;
		private var context3D:Context3D;
		private var indexBuffer:IndexBuffer3D;
		private var mvp:Matrix3D = new Matrix3D(); //ModelViewProjection
		private var modelMatrix:Matrix3D = new Matrix3D();
		private var cameraMatrix:Matrix3D = new Matrix3D();
		private var projectionMatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
		
		private var deviceInitialized:Boolean = false;
		private var deviceWasLost:Boolean = false;
		
		[Embed (source = "spaceship_texture.jpg")] 
		private var myTextureBitmap:Class;
		private var myTextureData:Bitmap = new myTextureBitmap();
		private var myTexture:Texture;
		
		[Embed (source = "spaceship.obj", mimeType = "application/octet-stream")] 
		private var myObjData:Class;
		private var myMesh:Stage3dObjParser;
		
		
		
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
			
			trace("isHardwareAccelerated? " , context3D.driverInfo.toLowerCase().indexOf("software") == -1);
			
			initProgram();
			initBuffers();
			initTexture();
			
			//projection
			projectionMatrix.perspectiveFieldOfViewLH(45*Math.PI/180 , stage.stageWidth/stage.stageHeight,0.1,30000);
			modelMatrix.appendTranslation(0,0,5);
			
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);

		}
		
		private function initProgram():void
		{
			AGAL.init();
			AGAL.m44("op","va0","vc0");
			AGAL.mov("v1","va1"); // uv
			
			var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexAssembler.assemble(Context3DProgramType.VERTEX,AGAL.code);
			
			//Create fragment assembler;
			AGAL.init();
			AGAL.tex("ft0","v1","fs0","2d","repeat","miplinear");
			AGAL.mov("oc","ft0");
			
			var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentAssembler.assemble(Context3DProgramType.FRAGMENT,AGAL.code);
			
			var program:Program3D = context3D.createProgram();
			program.upload(vertexAssembler.agalcode,fragmentAssembler.agalcode);
			context3D.setProgram(program);
		}
			
		private function initBuffers():void
		{
			myMesh = new Stage3dObjParser(myObjData, context3D, 1, true, true);
			context3D.setVertexBufferAt(0, myMesh.positionsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(1, myMesh.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			//context3D.setVertexBufferAt(2, myMesh.colorsBuffer, 0, Context3DVertexBufferFormat.FLOAT_4);
		}
		
		private function initTexture():void
		{
			myTexture = context3D.createTexture(512, 512, Context3DTextureFormat.BGRA, false);
			uploadTextureWithMipmaps(myTexture, myTextureData.bitmapData);
			context3D.setTextureAt(0, myTexture);
		}
		
		private function enterFrameHandler(pEvent:Event):void
		{
			modelMatrix.prependRotation(1,Vector3D.Y_AXIS);
			modelMatrix.prependRotation(2,Vector3D.X_AXIS);
			
			var cameraInvert:Matrix3D = cameraMatrix.clone();
			cameraInvert.invert();
			
			mvp.identity();
			mvp.append(modelMatrix);    //model to world space
			mvp.append(cameraInvert);   // world to eye space
			mvp.append(projectionMatrix); // eye space to clip space
			
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,mvp,true)
			
			context3D.clear();
			context3D.drawTriangles(myMesh.indexBuffer, 0, myMesh.indexBufferCount);	
			context3D.present();
			
		}
		
		public function uploadTextureWithMipmaps(dest:Texture, src:BitmapData):void
		{
			var ws:int = src.width;
			var hs:int = src.height;
			var level:int = 0;
			var tmp:BitmapData;
			var transform:Matrix = new Matrix();
			var tmp2:BitmapData;
			
			tmp = new BitmapData( src.width, src.height, true, 0x00000000);
			
			while ( ws >= 1 && hs >= 1 )
			{                                
				tmp.draw(src, transform, null, null, null, true);    
				dest.uploadFromBitmapData(tmp, level);
				transform.scale(0.5, 0.5);
				level++;
				ws >>= 1;
				hs >>= 1;
				if (hs && ws) 
				{
					tmp.dispose();
					tmp = new BitmapData(ws, hs, true, 0x00000000);
				}
			}
			tmp.dispose();
		}
		
		
		public function Test10()
		{
			initStage3D()
			
		}
	}
}