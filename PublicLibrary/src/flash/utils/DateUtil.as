package flash.utils
{
	import flash.globalization.DateTimeFormatter;
	import flash.globalization.LocaleID;

	/**
	 *	日期工具类 
	 * @author Huangm
	 */	
	public class DateUtil
	{
		/**
		 *	获取日期格式。
		 * 示例：
		 * <li>getDateFormat("yyyy-MM-dd HH:mm:ss"), 返回：2013-07-09 16:12:24</li>
		 * <li>geDateFormat("yyyyMMddhhmmss'.jpg'"), 返回：以时间命名的jpg文件名 2013070916152.jpg</li> 
		 * <li>getDateFormat("yyyy年MM月dd日 (EEEE) HH:mm:ss"), 返回：2013年07月09日 (星期二) 16:14:07 </li>
		 * @param pattern:String	设置日期和时间格式所用的模式字符串,defaule:"yyyy-MM-dd (EEEE) HH:mm:ss.SSS"
		 * @return 
		 */
		public static function getDateFormat(pattern:String = "yyyy-MM-dd (EEEE) HH:mm:ss.SSS", date:Date = null):String
		{
			var dtf:DateTimeFormatter = new DateTimeFormatter(LocaleID.DEFAULT);
			dtf.setDateTimePattern(pattern);
			
			return date == null ? dtf.format(new Date()) : dtf.format(date);
		}
		
		/**
		 *  获取毫秒数，因为setDateTimePattern()无法返回毫秒数，所以在这里临时加一个函数.
		 */
		public static function getMilliseconds():String
		{
			var ms:uint = new Date().milliseconds;
			var str:String = ms < 10 ? "00" + ms : ms < 100 ? "0" + ms : ms.toString();
			
			return str;
		}
	}
}