package flash.utils
{
	import flash.text.TextField;
	
	/**
	 * String处理类
	 */ 
	public class StringUtil
	{
		
		/**
		 *	如果指定的字符串是单个空格、制表符、回车符、换行符或换页符，则返回 true。 
		 * 	@character param1:String	查询的字符串。 
		 * 	@return	如果指定的字符串是单个空格、制表符、回车符、换行符或换页符，则为 true。 
		 */
		public static function isWhitespace(character:String) : Boolean
		{
			switch(character)
			{
				case " ":
				case "\t":
				case "\r":
				case "\n":
				case "\f":
					return true;
					break;
					
				default:
					return false;
					break;
			}
		}
		
		/**
		 * 	移除文本段落前的所有空格。
		 *  @param char:String 文本段落 
		 */ 
		public static function ltrim(char:String):String
		{
			var pattern:RegExp = /^\s*/g;
			
			return char = char == null ? null : char.replace(pattern, "");
		}
		
		/**
		 * 	移除文本段落后的所有空格。<br>
		 *  @param char:String 文本段落 
		 */ 
		public static function rtrim(char:String):String
		{
			var pattern:RegExp = /\s*$/g;
			
			return char = char == null ? null : char.replace(pattern, "");
		}
		
		/**
		 *	 除文本段落前后的所有空格
		 * @param char
		 */
		public static function trim(char:String):String
		{
			var s:String = StringUtil.ltrim(char);
			s = StringUtil.rtrim(s);
			
			return s;
		}
		
		/**
		 * 	移除文本段落中间的所有回车符。<br>
		 *  @param char:String 文本段落 
		 */ 
		public static function ctrim(char:String):String
		{
			var pattern:RegExp = /\r*/g;
			
			return char = char == null ? null : char.replace(pattern, "");
		}
		
		/**
		 *	将WEB特殊符号转为普通字符。 
		 * 	@param sc:String	特殊字符，以(&amp;)开始,分号(;)结束，的字符
		 * 	@return 返回转换后的字符
		 */		
		public static function specificSymbolToString(sc:String):String
		{
			var str:String;
			var re:RegExp = /^\&\w{1,};$/;
			
			if(re.test(sc))
			{
				switch(sc)
				{
					case "&amp;":
						str = "&";
						break;
					
					case "&apos;":
						str = "'";
						break;
					
					case "&gt;":
						str = ">";
						break;
					
					case "&lt;":
						str = "<";
						break;
					
					case "&quot;":
						str = "\"";
						break;
					
					default:
						str = sc;
				}
			}
			else
			{
				str = sc;
			}
			
			return str;
		}
		
		/**
		 * 将主机网卡MAC地址转为远程主机唤醒数据包。
		 * MAC地址示例：94-0C-6D-13-04-D6 或 94:0C:6D:13:04:D6
		 * 
		 * @pram mac:String 主机网卡MAC地址
		 * @return 返回ByteArray
		 * 
		 * @throws ArgumentError mac格式错误
		 * 
		 */ 
		public static function macToWOLData(mac:String):ByteArray
		{
			var ba:ByteArray = new ByteArray();
			var macArray:Array = [];
			
			var macRegExp:RegExp = /([[:xdigit:]]{2}[-:]){5}[[:xdigit:]]{2}/i;
			
			//trace(macRegExp.test(mac), mac);
			//if(RegExpUtil.MACADDRESS.test(mac))
			if(macRegExp.test(mac))
			{
				/**
				 * @internal
				 * 添加头部数据，拆分MAC地址。
				 */ 
				for(var i:int = 0; i < 6; i ++)
				{
					ba.writeByte(255);
					macArray[i] = "0x" + mac.substr(i * 3, 2);
				}
				
				/**
				 * @internal
				 * 添加十六次，把MAC拆分，转十进制
				 */ 
				for(var j:int = 0; j < 16; j ++)
				{
					for(var k:int = 0; k < 6; k ++)
					{
						//var num:int = int(Number("0x" + macArray[k]).toString(10));
						var num:Number = parseInt(macArray[k]);
						ba.writeByte(num);
					}
				}
			}
			else
			{
				throw new ArgumentError("StringUtil.macToWOLData(mac)参数格式错误！！");
			}
			
			return ba;
		}
		
		/**
		 * UTF8编码
		 * @param str:String 需要转码的文本
		 */ 
		public static function encodeUTF8(str:String):String
		{
			var oriByteArr:ByteArray = new ByteArray();
			oriByteArr.writeUTFBytes(str);
			
			var tempByteArr:ByteArray = new ByteArray();
		
			for (var i:int = 0; i < oriByteArr.length; i++)
			{
				if (oriByteArr[i] == 194)
				{
					tempByteArr.writeByte(oriByteArr[i+1]);
					i++;
				}
				else if (oriByteArr[i] == 195)
				{
					tempByteArr.writeByte(oriByteArr[i+1] + 64);
					i++;
				}
				else
				{
					tempByteArr.writeByte(oriByteArr[i]);
				}
			}
			
			tempByteArr.position = 0;
			return tempByteArr.readMultiByte(tempByteArr.bytesAvailable, "chinese");
		}
		
		//	日志记录。
		public static function traceLog(logTxt:TextField, ...args):void
		{
			var len:int = args.length;
			
			logTxt.appendText(DateUtil.getDateFormat("HH:mm:ss") + "  ");
			
			for(var i:int = 0; i < len; i ++)
			{
				logTxt.appendText(args[i] + "\t");
			}
			
			logTxt.appendText("\n---------------------------------------------------\n");
			logTxt.scrollV = logTxt.maxScrollV;
		}
		
		/**
		 *	转换Boolean 
		 * @param str:String	字符为不区分大小写的"true"或者"false"
		 * @return 如果字符为"true"，则返回true, 反之false
		 */
		public static function convertBolean(str:String):Boolean
		{
			str = str.toLowerCase();
			var boo:Boolean;
			
			if(str == "true" || str == "false")
			{
				boo = str == "true" ? true : false;
			}
			else
			{
				boo = false;	
			}
			
			return boo;
		}
	}
}