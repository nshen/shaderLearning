package effect
{
	public class ParticleEmitterBase
	{
		protected var _particleSystem:ParticleSystem;
		protected var _newParticleCount:Number = 0;
		
		public var emitPeriod:int = 5;		// 发射周期 （秒）
		public var emitTime:int = 1;		// 一次发射持续时间（秒）
		public var emitRate : int = 200;		// 发射率,每秒发射粒子数（秒）
		
		protected var pastTime:int = 0;		// 经过的时间 (毫秒)
		protected var inEmitTime : Boolean = true;		// 是否在发射的周期中
		
		public function update(elapsed:int):void
		{
			if(!_particleSystem)
				return ;
			
			pastTime += elapsed;
			if( emitPeriod <= 0 || emitTime >= emitPeriod)
				inEmitTime = true;
			else
			{
				var remainTime : int = pastTime % (emitPeriod * 1000 );
				inEmitTime = (remainTime <= emitTime * 1000);
			}
			if(!inEmitTime) return ;
			
			_newParticleCount += Number(elapsed * emitRate * 0.001) ; 
			while( _newParticleCount > 1)
			{
				var newParticle:Particle = _particleSystem.generateParticle();
				initParticle(newParticle);
				if(_particleSystem)
					_particleSystem.uploadParticle(newParticle);
				
				_newParticleCount--;
			}
		}
		
		protected function initParticle(newParticle:Particle):void
		{
			throw new Error();
		}
		
		public function set particleSystem(value:ParticleSystem) : void
		{
			if(_particleSystem)
			{	// 脱离当前发射器
				_particleSystem.emitter = null;
			}
			_particleSystem = value;
		}
	}
}