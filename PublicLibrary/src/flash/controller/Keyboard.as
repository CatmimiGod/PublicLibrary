package flash.controller
{
	public class Keyboard
	{
		/**
		 *	键名to键值 
		 * @param keyChar
		 * @return 
		 */		
		public static function name2Code(keyChar:String):uint
		{
			var code:uint = 0;
			
			if(keyChar.length == 1)
				return keyChar.charCodeAt(0);
			
			switch(keyChar.toUpperCase())
			{
				case "UP":
					return 38;
					
				case "DOWN":
					return 40;
					
				case "LEFT":
					return 37;
				
				case "RIGHT":
					return 39;
					
				case "PAGEUP":
					return 33;
					
				case "PAGEDOWN":
					return 34;
				
				case "HOME":
					return 36;
				
				case "END":
					return 35;
				
				case "ENTER":
					return 13;
				
				case "SPACE":
					return 32;
					
				case "<":
					return 188;
				
				case ">":
					return 190;
			}
			
			return 0;
		}
	}
}