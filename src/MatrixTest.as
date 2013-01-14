//http://blog.csdn.net/popy007/article/details/1797121 
//资料
package
{
	import flash.display.Sprite;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	[SWF(width="800" , height="800")]
	public class MatrixTest extends Sprite
	{
		public function MatrixTest()
		{
			super();
			var v:Vector.<Number>  = Vector.<Number>([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16])
			var m:Matrix3D = new Matrix3D(v);
			/*
			1,2,3,4,
			5,6,7,8,
			9,10,11,12,
			13,14,15,16
			*/
			
			/**
			 * 转置矩阵 :沿对角线翻折，转置再转置则还原
			 * m.transpose()
			/*
			1,5,9,13,
			2,6,10,14,
			3,7,11,15,
			4,8,12,16
			*/
				
			m.identity()
				
			/*
			单位矩阵
			1,0,0,0,
			0,1,0,0,
			0,0,1,0,
			0,0,0,1
			*/
				
				
			m.appendTranslation(5,6,7);
			
			/*
			
			1,0,0,0,
			0,1,0,0,
			0,0,1,0,
			x,y,z,w
			
			
			1,0,0,0,
			0,1,0,0,
			0,0,1,0,
			5,6,7,1
			*/
			
			//矩阵的每一行都能解释为转换后的基向量
			
			//向量乘以矩阵，变换
			var ve:Vector3D = new Vector3D(1,0,0);
//			trace(m.rawData ,m.transformVector(ve));
			
			//将物体变换一个量等价于将坐标系变换一个相反的量
			
			m.identity()
			m.appendRotation(30 ,Vector3D.Y_AXIS);
//			trace(m.rawData)
			/*
			
			1 0                  0                    0
			0 cos30              sin30                0,
			0,-sin30             cos30                0,
			0   0                 0                   1
			
			
			
			1,0,                 0,                   0,
			0,0.8660253882408142,0.5,                 0,
			0,-0.5,              0.8660253882408142,  0,
			0,0,      
			0,                   1
			*/
			
			m.identity();
			m.appendScale(4,5,6);
			trace(m.rawData);
		}
	}
}