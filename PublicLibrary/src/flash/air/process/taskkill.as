package flash.air.process
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.filesystem.File;
	import flash.system.Capabilities;

	/**
	 *	以cmd命令行的形式结束进程
	 * <br /><br />
	 * 示例： taskkill("DemoApplicationService.exe");
	 * 
	 * @param processName:String	进程名 
	 * 
	 * @playversion AIR
	 * @throws Error 此方法只适用于Win平台
	 */	
	public function taskkill(processName:String, cmdPath:String = "C:/Windows/System32/cmd.exe"):void
	{
		if(Capabilities.os.toLowerCase().indexOf("win") == -1)
			throw new Error("taskkill方法只适用于Win平台.");
		
		var cmdFile:File = new File(cmdPath);
		if(!cmdFile.exists)
			throw new ArgumentError("cmd执行文件路径：" + cmdPath + " 不存在.");
		
		var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
		startupInfo.executable = cmdFile;
		var process:NativeProcess = new NativeProcess();
		process.start(startupInfo);
		
		//trace("taskkill /f /im " + processName + "\n");
		process.standardInput.writeMultiByte("taskkill /f /im " + processName + "\n", "gb2312");
		process.standardInput.writeMultiByte("exit\n", "gb2312");
	}
}