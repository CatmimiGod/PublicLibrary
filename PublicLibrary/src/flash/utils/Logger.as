package flash.utils
{
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.globalization.DateTimeFormatter;
	import flash.globalization.LocaleID;
	
	/**
	 *	Logger Trace
	 * @author Huangm
	 * @playerversion	AIR 1.0
	 */	
	public class Logger
	{
		private static var _logFileStream:FileStream;
		
		private static var _today:String;
		
		/**
		 *	 开启或关闭日志记录
		 * @param value
		 */		
		public static function set enabled(value:Boolean):void
		{
			if(value)
			{
				_today = getDateFormat("yyyy/MM/dd");
				var logFile:File = new File(File.applicationDirectory.nativePath + "/Logs/" + _today + ".log");
				
				_logFileStream = new FileStream();
				_logFileStream.open(logFile, FileMode.APPEND);	//同步打开
				_logFileStream.writeUTFBytes("--------------------------" + getDateFormat("yyyy-MM-dd (EEEE) HH:mm:ss") + " Create Logger-------------------------- \r\n");
				
				NativeApplication.nativeApplication.addEventListener(Event.EXITING, onAppExitHandler, false, 0, true);
			}
			else
			{
				if(_logFileStream)
				{
					_logFileStream.close();
					_logFileStream = null;
				}
				
				NativeApplication.nativeApplication.removeEventListener(Event.EXITING, onAppExitHandler);
			}
		}
		
		/**
		 * @private 
		 * app exit handler.
		 */		
		private static function onAppExitHandler(e:Event):void
		{
			Logger.enabled = false;
		}
		
		/**
		 *	 跟踪输出
		 * @param args
		 */		
		public static function Trace(...args):void
		{
			trace(args);
			
			if(_logFileStream)
			{
				var len:int = args.length;
				var time:String = getDateFormat("[HH:mm:ss.") + getMilliseconds() + "] ";
				
				if(_today != getDateFormat("yyyy/MM/dd"))
					Logger.enabled = true;
				
				for(var i:int = 0; i < len; i ++)
				{
					_logFileStream.writeUTFBytes(time + args[i] + "\r\n");
				}
			}
		}
		
		/**
		 *	获取日期格式。
		 * 示例：
		 * <li>getDateFormat("yyyy-MM-dd HH:mm:ss"), 返回：2013-07-09 16:12:24</li>
		 * <li>geDateFormat("yyyyMMddhhmmss'.jpg'"), 返回：以时间命名的jpg文件名 2013070916152.jpg</li> 
		 * <li>getDateFormat("yyyy年MM月dd日 (EEEE) HH:mm:ss"), 返回：2013年07月09日 (星期二) 16:14:07 </li>
		 * @param pattern:String	设置日期和时间格式所用的模式字符串,defaule:"yyyy-MM-dd (EEEE) HH:mm:ss.SSS"
		 * @return 
		 */
		protected static function getDateFormat(pattern:String = "yyyy-MM-dd (EEEE) HH:mm:ss.SSS"):String
		{
			var dtf:DateTimeFormatter = new DateTimeFormatter(LocaleID.DEFAULT);
			dtf.setDateTimePattern(pattern);
			
			return dtf.format(new Date());
		}
		
		/**
		 *  获取毫秒数，因为setDateTimePattern()无法返回毫秒数，所以在这里临时加一个函数.
		 */
		protected static function getMilliseconds():String
		{
			var ms:uint = new Date().milliseconds;
			var str:String = ms < 10 ? "00" + ms : ms < 100 ? "0" + ms : ms.toString();
			
			return str;
		}
		
	}
}


