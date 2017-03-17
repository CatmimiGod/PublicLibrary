package flash.utils
{
	/**
	 *	正则表达试 
	 * @author Administrator
	 * 
	 */	
	public class RegExpUtil
	{
		/**
		 *	本地文件路径的正则表达式.<br />
		 * 	可分解为三部份:
		 * <ul>
		 * 	<li>文件所在盘符，例：F:</li>
		 * 	<li>文件所在文件夹路径</li>
		 * 	<li>文件名称，包括后缀类型</li>
		 * </ul>
		 */		
		public static const FILE_PATH:RegExp = /^([a-z]:)\/(.+\/)(.+\.\w+)$/i;
		
		/**
		 *	MAC地址 
		 */		
		public static const MAC_ADDRESS:RegExp = /([[:xdigit:]]{2}[-:]){5}[[:xdigit:]]{2}/i;
		
		/**
		 *	 匹配自定义变量%VAR%
		 */		
		public static const CUSTOM_VAR:RegExp = /%[a-zA-Z0-9_]+%/ig;
		
		/**
		 *	HTTP Header信息 第一行信息 
		 */		
		public static const HTTP_HEADER:RegExp = /^(GET|POST) (\S{1,}) (HTTP\/1\.1|HTTP\/1\.0)$/i;
		
		/**
		 * HTTP Header信息 除第一行信息外的其它信息
		 */		
		public static const HTTP_HEADER_LINE:RegExp = /^([A-Z]{1}[\w-]{1,}): ([\S ]{1,})/gm;
		
		/**
		 *	URL变量的正则表达式 
		 */		
		public static const URL_VARIABLES:RegExp = /(\w{1,}=[^&= ]{1,})|&/g;
		
	}
}