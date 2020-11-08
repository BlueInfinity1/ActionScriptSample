package
{

	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class RotatedRectangle
	{
		public var rect: Rectangle;
		public var angle: Number; //in radians!
		public var origin: Point;
		private var intersectInfo : IntersectInfo = new IntersectInfo();
		
		public function RotatedRectangle(x:Number, y:Number, width:Number, height:Number, angle: Number = 0)
		{
			this.rect = new Rectangle(x, y, width, height);
			this.angle = angle;
			this.origin = new Point((int)(width / 2), (int)(height / 2));
		}
		
		//a method for testing if the rotated rectangle intersects with another rotated rectangle
		public function Intersects(rect:RotatedRectangle):Boolean
		{
			return GetIntersectInfo(rect).intersects;
		}
		
		//a method for testing if the rotated rectangle intersects with another rotated rectangle
		//and getting additional information about the intersection
		public function GetIntersectInfo(rect:RotatedRectangle):IntersectInfo
		{
			//var origin1:Point = new Point((int) rect1.width / 2, (int) rect1.height / 2));
			//var origin2:Point = new Point((int) rect2.width / 2, (int) rect2.height / 2));
			
			//Calculate the Axis we will use to determine if a collision has occurred
			//Since the objects are rectangles, we only have to generate 4 Axis (2 for
			//each rectangle) since we know the other 2 on a rectangle are parallel.
			var rectangleAxis:Array = new Array();
			rectangleAxis.push(UpperRightCorner().subtract(UpperLeftCorner()));
			rectangleAxis.push(UpperLeftCorner().subtract(UpperRightCorner()));
			rectangleAxis.push(rect.UpperLeftCorner().subtract(rect.LowerLeftCorner()));
			rectangleAxis.push(rect.UpperLeftCorner().subtract(rect.UpperRightCorner()));

			//trace("TL: " + String(UpperLeftCorner()) + "TR: " + String(UpperRightCorner()));
			//trace("Hero: TL: " + String(rect.UpperLeftCorner()) + " TR: " + String(rect.UpperRightCorner()));
			
			//for (var i:int = 0; i < rectangleAxis.length; i++ )
			//trace(String(i) + " "+String(rectangleAxis[i]));
			
			//Cycle through all of the Axis we need to check. If a collision does not occur
			//on ALL of the Axis, then a collision is NOT occurring. We can then exit out 
			//immediately and notify the calling function that no collision was detected. If
			//a collision DOES occur on ALL of the Axis, then there is a collision occurring
			//between the rotated rectangles. We know this to be true by the Seperating Axis Theorem
			//Keep track of the axis with smallest depth of overlap and return that for collision
			//response purposes.
			var minAxis : Point;
			var minDepth : Number = Infinity;
			for each (var axis:Point in rectangleAxis)
			{
				axis.normalize(1.0);
				var depth : Number = AxisCollisionDepth(rect, axis);
				if (depth == 0.0)
				{
					intersectInfo.intersects = false;
					intersectInfo.axis = null;
					intersectInfo.depth = 0.0;
					return intersectInfo;
				}
				else if (Math.abs(depth) < Math.abs(minDepth)) {
					minAxis = axis;
					minDepth = depth;
				}
			}
			minAxis.normalize(1);
			intersectInfo.intersects = true;
			intersectInfo.axis = minAxis;
			intersectInfo.depth = minDepth;
			return intersectInfo;
		}
		
		// Determines if a collision has occurred on an Axis of one of the
		// planes parallel to the Rectangle and returns the depth and direction of the overlap
		private function AxisCollisionDepth(rect:RotatedRectangle, axis:Point):Number
		{
			//Project the corners of the Rectangle we are checking on to the Axis and
			//get a scalar value of that project we can then use for comparison
			var rectAScalars: Array = new Array();
			rectAScalars.push(GenerateScalar(rect.UpperLeftCorner(), axis));
			rectAScalars.push(GenerateScalar(rect.UpperRightCorner(), axis));
			rectAScalars.push(GenerateScalar(rect.LowerLeftCorner(), axis));
			rectAScalars.push(GenerateScalar(rect.LowerRightCorner(), axis));

			//Project the corners of the current Rectangle on to the Axis and
			//get a scalar value of that project we can then use for comparison
			var rectBScalars: Array = new Array();
			rectBScalars.push(GenerateScalar(UpperLeftCorner(), axis));
			rectBScalars.push(GenerateScalar(UpperRightCorner(), axis));
			rectBScalars.push(GenerateScalar(LowerLeftCorner(), axis));
			rectBScalars.push(GenerateScalar(LowerRightCorner(), axis));

			//Get the Maximum and Minium Scalar values for each of the Rectangles
			var rectAMin:int = arrayMin(rectAScalars);
			var rectAMax:int = arrayMax(rectAScalars);
			var rectBMin:int = arrayMin(rectBScalars);
			var rectBMax:int = arrayMax(rectBScalars);

			//trace(String(rectAMin) + " " +String(rectAMax) + " " + String(rectBMin) + " " + String(rectBMax));
			
			// return the amount and direction of overlap in intervals defined by min(A/B) and max(A/B).
			return IntervalOverlap(rectAMin, rectAMax, rectBMin, rectBMax);
		}
		
		public function IntervalOverlap(minA:Number, maxA:Number, minB:Number, maxB:Number) : Number
		{
			var depth : Number;
			if ( minA < minB ) depth = minB - maxA;
			else depth = minA - maxB;
			if (depth < 0.0) {
				if (minA < minB) return -depth;
				else return depth;
			}
			else return 0.0;
		}

		
		// Generates a scalar value that can be used to compare where corners of 
		// a rectangle have been projected onto a particular axis. 
		private function GenerateScalar(rectCorner:Point, axis:Point):int
		{
			//Using the formula for Vector projection. Take the corner being passed in
			//and project it onto the given Axis
			var numerator:Number = (rectCorner.x * axis.x) + (rectCorner.y * axis.y);
			var denominator:Number = (axis.x * axis.x) + (axis.y * axis.y);
			var divisionResult:Number = numerator / denominator;
			var cornerProjected:Point = new Point(divisionResult * axis.x, divisionResult * axis.y);
			
			//Now that we have our projected Vector, calculate a scalar of that projection
			//that can be used to more easily do comparisons
			var scalar:Number = (axis.x * cornerProjected.x) + (axis.y * cornerProjected.y);
			return (int)(scalar);
		}

		// Rotate a point from a given location and adjust using the Origin we
		// are rotating around
		private function RotatePoint(point:Point, rectOrigin:Point, rotation:Number):Point
		{
			var translatedPoint:Point = new Point();
			translatedPoint.x = (Number)(rectOrigin.x + (point.x - rectOrigin.x) * Math.cos(rotation)
				- (point.y - rectOrigin.y) * Math.sin(rotation));
				translatedPoint.y = (Number)(rectOrigin.y + (point.y - rectOrigin.y) * Math.cos(rotation)
				+ (point.x - rectOrigin.x) * Math.sin(rotation));
			return translatedPoint;
		}
				
		public function UpperLeftCorner():Point
		{
			var upperLeft:Point = new Point(rect.x, rect.y);
			upperLeft = RotatePoint(upperLeft, upperLeft.add(origin), angle);
			return upperLeft;
		}

		public function UpperRightCorner():Point
		{
			var upperRight:Point = new Point(rect.right, rect.y);
			upperRight = RotatePoint(upperRight, upperRight.add(new Point(-origin.x, origin.y)), angle);
			return upperRight;
		}

		public function LowerLeftCorner():Point
		{
			var lowerLeft:Point = new Point(rect.x, rect.bottom);
			lowerLeft = RotatePoint(lowerLeft, lowerLeft.add(new Point(origin.x, -origin.y)), angle);
			return lowerLeft;
		}

		public function LowerRightCorner(): Point
		{
			var lowerRight:Point = new Point(rect.right, rect.bottom);
			lowerRight = RotatePoint(lowerRight,lowerRight.add(new Point(-origin.x, -origin.y)), angle);
			return lowerRight;
		}
		public static function arrayMin (array: Array):Number
		{
			//should throw an error with null arrays
			var min:Number = array[0];
			for (var i:int = 1; i < array.length; i++)
			{
				if (array[i] < min)
				min = array[i];
			}
			return min;
		}
		public static function arrayMax (array: Array):Number
		{
			//should throw an error with null arrays
			var max:Number = array[0];
			for (var i:int = 1; i < array.length; i++)
			{
				if (array[i] > max)
				max = array[i];
			}
			return max;
		}

	}
}
