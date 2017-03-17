package flash.air.process
{
	import flash.air.process.CommandProcess;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.filesystem.File;

	/**
	 *	桌面进程控制对象，就是退出/启动explorer.exe进程
	 * @author Administrator
	 */	
	public final class ExplorerProcess
	{
		/**
		 *	退出桌面进程 
		 */		
		public static function exitExplorer():void
		{
			var cmdProcess:CommandProcess = new CommandProcess();
			cmdProcess.execute("taskkill /f /im explorer.exe");
			cmdProcess.dispose();
		}
		
		/**
		 *	启动桌面进程 
		 */		
		public static function startExplorer():void
		{
			var file:File = new File("C:/Windows/explorer.exe");
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.executable = file;
			
			var process:NativeProcess = new NativeProcess();
			process.start(info);
		}
	}
}