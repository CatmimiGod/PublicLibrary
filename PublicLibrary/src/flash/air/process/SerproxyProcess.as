package flash.air.process
{
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.utils.ByteArray;

	/**
	 *	Serproxy.exe 进程 
	 * @playvsersion AIR
	 * @author huangm
	 */	
	public class SerproxyProcess
	{
		protected static var _localProcess:LocalProcess;
		
		/**
		 *	启动Serproxy.exe进程<br />
		 *  <b>启动路径(项目路径)中不能包含中文字符</b>
		 */
		public static function start(autoExit:Boolean = true):void
		{
			var path:String = File.applicationDirectory.nativePath + "\\assets\\serproxy-0.1.3-3.bin.win32\\";
			
			var bytes:ByteArray = new ByteArray();
			bytes.writeMultiByte(path.substr(0, 2) + "\n", "gb2312");
			bytes.writeMultiByte("cd " + path + "\n", "gb2312");
			bytes.writeMultiByte("start /min serproxy.exe\n", "gb2312");
			
			_localProcess = new LocalProcess(new File("C:/Windows/System32/cmd.exe"));
			_localProcess.standardInput.writeBytes(bytes, 0, bytes.length);
			
			if(autoExit)
				NativeApplication.nativeApplication.addEventListener(Event.EXITING, exit);
		}
		
		/**
		 *	退出Serproxy.exe进程
		 */
		public static function exit(e:Event = null):void
		{
			if(_localProcess)
				_localProcess.writeUTFBytes("taskkill /f /im serproxy.exe");
		}
		
	}
}