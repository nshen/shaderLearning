package effect
{
	
	import effect.Particle;
	import effect.ParticleEmitterBase;
	
	import flash.geom.Vector3D;
	
	public class RectangleParticleEmitter extends ParticleEmitterBase
	{
		
		public var lifeTime : int = 1000;		// 生命期(毫秒ms)
		public var lifeTimeRange : int = 0;	// 生命期变化
		public var color : uint = 0xff0055;	// 颜色
		public var colorRange : uint = 0x000000;	// 颜色变化值
		public var alpha : Number = 1;			// 透明度
		public var alphaRange : Number = 0;	// 透明度变化值
		public var sizeX : Number = 50;			// 大小
		public var sizeY : Number = 50;			// 大小
		public var sizeRange : Number = 0;		// 大小变化		
		public var directionFrom : Vector3D = new Vector3D(0,1,0);			// 发射方向
		public var directionTo : Vector3D = new Vector3D(0,1,0);	// 发射角度变化范围
		public var vel : int = 100;		// 运动速度(每秒)
		public var velRange : int = 0;		// 运动速度变化范围
		public var rot : Number = 0;		// 初始角度(弧度)
		public var rotRange : Number = 0;	// 初始角度变化
		public var rotVel : Number = 1;			// 旋转速度
		public var rotVelRange : Number = 0;		// 旋转速度变化
		public var EmitterRectFrom : Vector3D = new Vector3D(-200,-200,0);		// 发射器矩形生成范围
		public var EmitterRectTo : Vector3D = new Vector3D(200,200,0);
		
		
		public function RectangleParticleEmitter()
		{
			super();
		}
		
		
		override protected function initParticle(newParticle:Particle) : void
		{
			// 颜色
			newParticle.color = color + colorRange * Math.random();
			// 透明度
			newParticle.alpha = alpha + alphaRange * Math.random();
			// uv
			newParticle.u = 0;
			newParticle.v = 0;
			// 生命期
			newParticle.remainTime = lifeTime + lifeTimeRange * Math.random();
			// 方向
			newParticle.dir.x = directionFrom.x * Math.random() + directionTo.x * Math.random();
			newParticle.dir.y = directionFrom.y * Math.random() + directionTo.y * Math.random();
			newParticle.dir.z = directionFrom.z * Math.random() + directionTo.z * Math.random();
			newParticle.dir.normalize();
			// 移动速度
			newParticle.vel = vel + velRange * Math.random();
			// 大小
			var sizeRand : Number = sizeRange * Math.random();
			newParticle.sizeX = sizeX + sizeRand;
			newParticle.sizeY = sizeY + sizeRand;
			// 旋转
			newParticle.rot = rot +  rotRange * Math.random();
			// 旋转速度
			newParticle.rotVel = rotVel + rotVelRange * Math.random();
			
			newParticle.pos.x += (EmitterRectTo.x - EmitterRectFrom.x) * Math.random() + EmitterRectFrom.x;
			newParticle.pos.y += (EmitterRectTo.y - EmitterRectFrom.y) * Math.random() + EmitterRectFrom.y;
			newParticle.pos.z += (EmitterRectTo.z - EmitterRectFrom.z) * Math.random() + EmitterRectFrom.z;
		}
	}
}