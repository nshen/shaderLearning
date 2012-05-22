//from : http://code.google.com/p/bwhiting/source/browse/trunk/b3d/src/b3d/materials/shaders/AGAL.as
package
{
	public class AGAL
	{
		private static var _code:String = "";
		public static var _traceCode:Boolean = true ;
		public static function init():void
		{
			_code = "";
		}
		public static function get code():String
		{
			var code:String = _code.toString();
			_code = "";
			if(_traceCode)
				trace(code);
			return code;
		}
		/**BLENDING**/
		
		//
		/**UTILS**/
		//returns the length of a source
		public static function length(target:String, source:String):String
		{
			var code:String = "";
			code += dp3(target, source, source);
			code += sqt(target, target);
			_code += code;
			return code;
		}
		//same as mix() in opengl but slower: 
		//dest = source1 + (source2 - source1) * ratio;
		//或者解释成dest = (1-ratio)source1 + ratio source2
		public static function lerp(target:String, source1:String, source2:String, ratio:String):String
		{
			if(target == source1 || target == source2)
				throw new Error("target 不能与源重名");
			var code:String = "";
			code += sub(target, source2, source1);
			code += mul(target, target, ratio);
			code += add(target, target, source1);
			_code += code;
			return code;
		}
		//distance between two points
		public static function distance(target:String, source1:String, source2:String):String
		{
			var code:String = "";
			code += sub(target, source2, source1);
			code += length(target, target);
			_code += code;
			return code;
		}
		public static function smoothstep(target:String, min:String, max:String, x:String, TWO:String, THREE:String, temp:String):String
		{
			var code:String = "";
			// Scale, bias and saturate x to 0..1 range
			code += sub(target, max, min);
			code += sub(temp, x, min);
			code += div(target, temp, target);
			code += sat(target, target);
			// Evaluate polynomial
			code += mul(temp, TWO, target);
			code += sub(temp, THREE, temp);
			code += mul(target, target, target);
			code += mul(target, target, temp);
			_code += code;
			return code;
		}
		//unit vector from Vertex to Vertex
		public static function direction(target:String, source1:String, source2:String):String
		{
			var code:String = "";
			code += sub(target, source2, source1);
			code += nrm(target+".xyz", target);
			_code += code;
			return code;
		}
		//unit vector from Light to the Vertex position
		public static function light(target:String, light:String, position:String):String
		{
			var code:String = "";
			code += sub(target, position, light);
			code += nrm(target+".xyz", target);
			_code += code;
			return code;
		}
		//unit vector from Vertex P to the View position V
		public static function view(target:String, position:String, camera:String):String
		{
			var code:String = "";
			code += sub(target, camera, position);
			code += nrm(target+".xyz", target);
			_code += code;
			return code;
		}
		//unit vector halfway H, between L and V, used for Blinn simplification
		public static function half(target:String, light:String, view:String):String
		{
			var code:String = "";
			code += sub(target, view, light);
			code += nrm(target+".xyz", target);
			_code += code;
			return code;
		}
		//unit vector representing light reflection R
		public static function reflect(target:String, view:String, normal:String):String
		{
			// r = V - 2(V.N)*N
			var code:String = "";
			code += dp3(target, view, normal);
			code += add(target, target, target);
			code += mul(target, normal, target);
			code += sub(target, view, target);
			code += neg(target, target);
			code += nrm(target+".xyz", target);                     //added
			/*
			//                      var code:String = "";
			//                      code += dp3(target+".w", view+".xyz", normal+".xyz");
			//                      code += add(target+".w", target+".w", target+".w");
			//                      code += mul(target+".xyz", normal+".xyz", target+".w");
			//                      code += sub(target+".xyz", view+".xyz", target+".xyz");
			//                      code += neg(target+".xyz", target+".xyz");
			//                      code += nrm(target+".xyz", target);                     //added*/
			_code += code;
			return code;
		}
		public static function refract(target:String, view:String, normal:String, temp:String, one:String, ratio:String, ratioSquare:String):String
		{
			var code:String = "";
			code += dp3(temp, view, normal);
			code += mul(temp, temp, normal);
			code += sub(temp, temp, view);
			code += mul(temp, temp, ratio);
			
			code += dp3(target, view, normal);
			code += mul(target, target, target);
			code += sub(target, one, target);
			code += mul(target, ratioSquare, target);    
			code += sub(target, one, target);
			code += sqt(target, target);
			code += mul(target, target, normal);
			code += sub(target, temp, target);      
			//code += nrm(target+".xyz", target);                   //added                         
			_code += code;
			return code;
		}
		
		public static function fresnel(target:String, view:String, normal:String):String
		{
			var code:String = "";
			code += dp3(target, view+".xyz", normal+".xyz");
			_code += code;
			return code;
		}
		//1-fres not done yet.!!!!!
		public static function fresnel_inv(target:String, view:String, normal:String, one:String):String
		{
			var code:String = "";
			code += dp3(target, view+".xyz", normal+".xyz");
			code += sub(target, one, target);
			_code += code;
			return code;
		}
		
		/**LIGHTING HELPERS**/
		public static function diffuse(target:String, fresnel:String, diffuseData:String):String
		{
			var code:String = "";
			code += mul(target, fresnel, diffuseData);
			_code += code;
			return code;
		}
		public static function diffuse2(target:String, viewTarget:String, fresnelTarget:String, position:String, camera:String, normal:String, diffuseData:String):String
		{
			var code:String = "";
			code += view(viewTarget, position, camera);
			code += fresnel(fresnelTarget, viewTarget, normal);                     
			code += mul(target, fresnelTarget, diffuseData);
			_code += code;
			return code;
		}
		public static function diffuse3(target:String, normal:String, lightDirection:String, diffuseData:String):String
		{
			var code:String = "";
			code += fresnel(target, lightDirection, normal);
			code += mul(target, target, diffuseData);
			_code += code;
			return code;
		}
		//specular data = [spec col * spec intens, pow]
		public static function specularPhong(target:String, reflect:String, view:String, specularData:String):String
		{
			//pow(saturate(dot(Reflect, ViewDir)), 15)
			var code:String = "";
			code += dp3(target, reflect, view+".xyz");                      //dp3 reflect with view
			code += pow(target, target, specularData+".w");         //pow with shinneyness
			code += mul(target, target, specularData+".xyz");       //multiply with spec data
			_code += code;
			return code;
		}
		public static function specularBlinnPhong(target:String, half:String, normal:String, specularData:String):String
		{
			//pow(saturate(dot(Half, ViewDir)), 15)
			var code:String = "";
			code += dp3(target, half, normal+".xyz");                       //dp3 half vector with ws_normal
			code += pow(target, target, specularData+".w");         //pow with shinneyness
			code += mul(target, target, specularData+".xyz");       //multiply with spec data
			_code += code;
			return code;
		}
		public static function specularBlinnPhong2(target:String, light:String, view:String, normal:String, specularData:String):String
		{
			//pow(saturate(dot(Half, ViewDir)), 15)
			var code:String = "";
			code += half(target, light, view);                                      //half now in target
			code += dp3(target, target, normal+".xyz");                     //dp3 half vector with ws_normal
			code += pow(target, target, specularData+".w");         //pow with shinneyness
			code += mul(target, target, specularData+".xyz");       //multiply with spec data
			_code += code;
			return code;
		}
		
		/**AGAL COMMANDS**/
		//move data from source1 to destination, componentwise
		public static function mov(target:String, source:String):String
		{
			var code:String = "mov " + target + " " + source + "\n";
			_code += code;
			return code;
		}
		//destination = source1 + source2, componentwise
		public static function add(target:String, source1:String, source2:String):String
		{
			var code:String = "add " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = source1 - source2, componentwise
		public static function sub(target:String, source1:String, source2:String):String
		{
			var code:String = "sub " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = source1 * source2, componentwise
		public static function mul(target:String, source1:String, source2:String):String
		{
			var code:String = "mul " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = source1 / source2, componentwise
		public static function div(target:String, source1:String, source2:String):String
		{
			var code:String = "div " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = 1/source1, componentwise
		public static function rcp(target:String, source1:String, source2:String):String
		{
			var code:String = "rcp " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = minimum(source1,source2), componentwise
		public static function min(target:String, source1:String, source2:String):String
		{
			var code:String = "min " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = maximum(source1,source2), componentwise
		public static function max(target:String, source1:String, source2:String):String
		{
			var code:String = "max " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = source1 - (float)floor(source1), componentwise
		public static function frc(target:String, source1:String):String
		{
			var code:String = "frc " + target + " " + source1 + "\n";
			_code += code;
			return code;
		}
		//destination = sqrt(source1), componentwise
		public static function sqt(target:String, source:String):String
		{
			var code:String = "sqt " + target + " " + source + "\n";
			_code += code;
			return code;
		}
		//destination = 1/sqrt(source1), componentwise
		public static function rsq(target:String, source:String):String
		{
			var code:String = "rsq " + target + " " + source + "\n";
			_code += code;
			return code;
		}
		//destination = pow(source1,source2), componentwise
		public static function pow(target:String, source1:String, source2:String):String
		{
			var code:String = "pow " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = log_2(source1), componentwise
		public static function log(target:String, source:String):String
		{
			var code:String = "log " + target + " " + source + "\n";
			_code += code;
			return code;
		}
		//destination = 2^source1, componentwise
		public static function exp(target:String, source:String):String
		{
			var code:String = "exp " + target + " " + source + "\n";
			_code += code;
			return code;
		}
		//destination = normalize(source1), componentwise
		public static function nrm(target:String, source:String):String
		{
			if(target.indexOf(".") == -1) target += ".xyz"; //w must be masked
			var code:String = "nrm " + target + " " + source + "\n";
			_code += code;
			return code;
		}
		//destination = sin(source1), componentwise
		public static function sin(target:String, source:String):String
		{
			_code += code;
			return code;
			var code:String = "sin " + target + " " + source + "\n";
		}
		//destination = cos(source1), componentwise
		public static function cos(target:String, source:String):String
		{
			var code:String = "cos " + target + " " + source + "\n";
			_code += code;
			return code;
		}
		//destination.x = source1.y * source2.z - source1.z * source2.y
		//destination.y = source1.z * source2.x - source1.x * source2.z
		//destination.z = source1.x * source2.y - source1.y * source2.x
		public static function crs(target:String, source1:String, source2:String):String
		{
			var code:String = "crs " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = source1.x*source2.x + source1.y*source2.y
		public static function dp2(target:String, source1:String, source2:String):String
		{
			var code:String = "";
			code += mul(target+".x", source1+".x", source2+".x");
			code += mul(target+".y", source1+".y", source2+".y");
			code += add(target, target+".x", target+".y");                  
			_code += code;
			return code;
		}
		//destination = source1.x*source2.x + source1.y*source2.y + source1.z*source2.z
		public static function dp3(target:String, source1:String, source2:String):String
		{
			var code:String = "dp3 " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = source1.x*source2.x + source1.y*source2.y + source1.z*source2.z + source1.w*source2.w
		public static function dp4(target:String, source1:String, source2:String):String
		{
			var code:String = "dp4 " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = abs(source1), componentwise
		public static function abs(target:String, source:String):String
		{
			var code:String = "abs " + target + " " + source + "\n";
			_code += code;
			return code;
		}
		//destination = -source1, componentwise
		public static function neg(target:String, source:String):String
		{
			var code:String = "neg " + target + " " + source + "\n";
			_code += code;
			return code;
		}
		//destination = maximum(minimum(source1,1),0), componentwise
		public static function sat(target:String, source:String):String
		{
			var code:String = "sat " + target + " " + source + "\n";
			_code += code;
			return code;
		}
		//destination.x = (source1.x * source2[0].x) + (source1.y * source2[0].y) + (source1.z * source2[0].z)
		//destination.y = (source1.x * source2[1].x) + (source1.y * source2[1].y) + (source1.z * source2[1].z)
		//destination.z = (source1.x * source2[2].x) + (source1.y * source2[2].y) + (source1.z * source2[2].z)
		public static function m33(target:String, source1:String, source2:String):String
		{
			if(target.indexOf(".") == -1) target += ".xyz"; //w must be masked
			var code:String = "m33 " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//
		
		/*
		* destination.x = (source1.x * source2[0].x) + (source1.y * source2[0].y) + (source1.z * source2[0].z) + (source1.w * source2[0].w)
		* destination.y = (source1.x * source2[1].x) + (source1.y * source2[1].y) + (source1.z * source2[1].z) + (source1.w * source2[1].w)
		* destination.z = (source1.x * source2[2].x) + (source1.y * source2[2].y) + (source1.z * source2[2].z) + (source1.w * source2[2].w)
		* destination.w = (source1.x * source2[3].x) + (source1.y * source2[3].y) + (source1.z * source2[3].z) + (source1.w * source2[3].w)
		*/
		public static function m44(target:String, source1:String, source2:String):String
		{
			var code:String = "m44 " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination.x = (source1.x * source2[0].x) + (source1.y * source2[0].y) + (source1.z * source2[0].z) + (source1.w * source2[0].w)
		//destination.y = (source1.x * source2[1].x) + (source1.y * source2[1].y) + (source1.z * source2[1].z) + (source1.w * source2[1].w)
		//destination.z = (source1.x * source2[2].x) + (source1.y * source2[2].y) + (source1.z * source2[2].z) + (source1.w * source2[2].w)
		public static function m34(target:String, source1:String, source2:String):String
		{
			var code:String = "m34 " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}               
		//(fragment shader only) If single scalar source component is less than zero, fragment is discarded and not drawn to the frame buffer. The destination register must be all 0. 
		public static function kil(target:String, source:String):String
		{
			var code:String = "kil " + target + " " + source + "\n";
			_code += code;
			return code;
		}
		//(fragment shader only) destination = load from texture source2 at coordinates source1. In this source2 must be in sampler format.
		public static function tex(target:String, coord:String, texture:String, type:String, wrap:String, filter:String):String
		{
			//type: 2d, 3d, cube
			//wrap: clamp, repeat
			//filter: mipnearest, miplinear, mipnone, nomip, nearest, linear, centroid, single, depth
			var code:String = "tex "+target+" "+coord+" "+texture+" <"+type+","+wrap+","+filter+">" + "\n";
			_code += code;
			return code;
		}
		//(fragment shader only) 
		public static function texCube(target:String, coord:String, texture:String, filter:String):String
		{
			//filter: mipnearest, miplinear, mipnone, nomip, nearest, linear, centroid, single, depth
			var code:String = "tex "+target+" "+coord+" "+texture+" <cube, clamp,"+filter+">" + "\n";
			_code += code;
			return code;
		}
		
		
		//destination = source1 >= source2 ? 1 : 0, componentwise
		public static function sge(target:String, source1:String, source2:String):String
		{
			var code:String = "sge " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		//destination = source1 < source2 ? 1 : 0, componentwise
		public static function slt(target:String, source1:String, source2:String):String
		{
			var code:String = "slt " + target + " " + source1 + " " + source2 + "\n";
			_code += code;
			return code;
		}
		
		
		//converters
		public static function vectorToColor(target:String, vector:String, one:String,two:String):String
		{
			var code:String = "";
			code += add(target, vector, one);
			code += div(target, target, two);
			_code += code;
			return code;
		}
		public static function colorToVector(target:String, color:String, half:String, two:String):String
		{
			var code:String = "";
			code += sub(target, color, half);
			code += mul(target, target, two);
			_code += code;
			return code;
		}
		
		
		
		/**WTF SECTION...anyone who knows what these do let me know an ill wang em in*/
		/*
		ifz
		inz
		ife
		ine
		ifg
		ifl
		ieg
		iel
		els
		eif
		rep
		erp
		brk
		sgn
		*/
		
		//target must not be empty (zeroed)
		//sample is just a temp
		//normalized boolean parameter?
		public static function convolve(target:String, sample:String, texture:String, uv:String, offset:String, filter:String, divisor:String = null, bias:String = null):String
		{
			var num:int = int(filter.substr(2));
			var row1:String = "fc"+num;
			var row2:String = "fc"+num+1;
			var row3:String = "fc"+num+2;
			
			var code:String = "";                   
			code +=
				
				//TOP-LEFT
				mov(sample, uv)+
				add(sample+".y", sample+".y", offset)+
				sub(sample+".x", sample+".x", offset)+
				tex(sample, sample, texture, "2d", "clamp", "linear")+
				mul(sample, sample, row1+".x")+
				add(target, target, sample)+
				
				//TOP
				mov(sample, uv)+
				add(sample+".y", sample+".y", offset)+
				tex(sample, sample, texture, "2d", "clamp", "linear")+
				mul(sample, sample, row1+".y")+
				add(target, target, sample)+
				
				//TOP-RIGHT
				mov(sample, uv)+
				add(sample+".y", sample+".y", offset)+
				add(sample+".x", sample+".x", offset)+
				tex(sample, sample, texture, "2d", "clamp", "linear")+
				mul(sample, sample, row1+".z")+
				add(target, target, sample)+
				
				//MIDDLE-LEFT
				mov(sample, uv)+
				sub(sample+".x", sample+".x", offset)+
				tex(sample, sample, texture, "2d", "clamp", "linear")+
				mul(sample, sample, row2+".x")+
				add(target, target, sample)+
				
				//MIDDLE
				mov(sample, uv)+
				tex(sample, sample, texture, "2d", "clamp", "linear")+
				mul(sample, sample, row2+".y")+
				add(target, target, sample)+
				
				//MIDDLE-RIGHT
				mov(sample, uv)+
				add(sample+".x", sample+".x", offset)+
				tex(sample, sample, texture, "2d", "clamp", "linear")+
				mul(sample, sample, row2+".z")+
				add(target, target, sample)+
				
				//BOTTOM-LEFT
				mov(sample, uv)+
				sub(sample+".y", sample+".y", offset)+
				sub(sample+".x", sample+".x", offset)+
				tex(sample, sample, texture, "2d", "clamp", "linear")+
				mul(sample, sample, row3+".x")+
				add(target, target, sample)+
				
				//BOTTOM
				mov(sample, uv)+
				sub(sample+".y", sample+".y", offset)+
				tex(sample, sample, texture, "2d", "clamp", "linear")+
				mul(sample, sample, row3+".y")+
				add(target, target, sample)+
				
				//BOTTOM-RIGHT
				mov(sample, uv)+
				sub(sample+".y", sample+".y", offset)+
				add(sample+".x", sample+".x", offset)+
				tex(sample, sample, texture, "2d", "clamp", "linear")+
				mul(sample, sample, row3+".z")+
				add(target, target, sample);
			
			if(divisor!=null) code += div(target, target, divisor);
			if(bias!=null) code += add(target, target, bias);
			
			_code += code;
			return code;
		}
	}
}
