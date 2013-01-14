package effect
{
	import flash.geom.Vector3D;

	public class Particle
	{
		public var index : int;			// 在particleSystem中的index
		public var noDead : Boolean = false;	// 不会死亡
		private var _remainTime : int = 0;			// 剩下的时间 ( >0 活 <=0 死 )
		public var pastTime : int = 0;			// 经过的时间（ 经过的时间+剩下的时间=生命期 ）
		public var pos : Vector3D= new Vector3D;			// 位置
		public var dir : Vector3D = new Vector3D;			// 运动方向
		public var vel : Number = 0;			// 运动速度
		public var sizeX : Number  = 0;		// 大小
		public var sizeY : Number = 0;
		
		public var rot : Number = 0;			// 旋转(顺时针,弧度)
		public var rotVel : Number = 0;		// 旋转速度(每秒)
		public var color : uint = 0xff0044;	// 颜色
		public var alpha : Number = 1.0;		// 透明度[0,1] 
		public var u : Number = 0.0;			// u offset
		public var v : Number = 0.0;			// v offset
		public var su : Number = 1.0;			// u scale
		public var sv : Number = 1.0;			// v scale
		
		public function Particle(index:int)
		{
			this.index = index;
		}
		
		public function get r() : Number {return ((color & 0xff0000) >> 16) / 0xff;}
		public function get g() : Number {return ((color & 0x00ff00) >> 8) / 0xff;}
		public function get b() : Number {return (color & 0x0000ff) / 0xff;}
		
		public function reset() : void
		{
			_remainTime = 0;
			pastTime = 0;
			sizeX = 0;
			sizeY = 0;
			vel = 0;
			rot = 0;
			rotVel = 0;
			color = 0xff0055;
			alpha = 1.0;
			u = 0;
			v = 0;
			pos.setTo(0,0,0);
			dir.setTo(0,1,0);
		}
		
		// 设置粒子的生命
		public function set remainTime(value : int) : void
		{
			_remainTime = value;
			pastTime = 0;
		}
		
		public function get remainTime() : int {return _remainTime;}
		
		public function isDead() : Boolean {return _remainTime <= 0 && !noDead ; } 
		public function die() : void { pastTime += _remainTime; _remainTime = 0; noDead = false; }
		
		public function update(elapsed :int) : void
		{
			_remainTime -= elapsed;
			pastTime += elapsed;
			
			if(noDead && _remainTime<=0)
			{
				_remainTime = pastTime + _remainTime;
				pastTime = 0;
			}
		}
	}
}