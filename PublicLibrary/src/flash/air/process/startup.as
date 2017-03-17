package flash.air.process
{
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	
	/**
	 *	使用cmd命令行的形式，以最小化启动程序或进程，无任何其它操作，返回进程名称
	 * <br /><br />
	 * 示例：
	 * startup("release/DemoApplicationService.exe");
	 * 
	 * @param exePath:String
	 * @param exeArgs:String	程序的启动参数，可为空
	 * @param startArgs:String	start命令行的参数 "/min"最小化, "/max"最大化
	 * @param cmdPath:String
	 * 
	 * @playversion AIR
	 * 
	 * @throws Error 此方法只适用于Win平台
	 * @throws ArgumentError 文件不存在
	 */		
	public function startup(exePath:String, exeArgs:String = null, startArgs:String = "/min", cmdPath:String = "C:/Windows/System32/cmd.exe"):void
	{
		if(Capabilities.os.toLowerCase().indexOf("win") == -1)
			throw new Error("startup方法只适用于Win平台.");
		
		if(exePath == null)
			throw new ArgumentError("函数 startup 参数 exePath 不参为空.");
		
		var cmdFile:File = new File(cmdPath);
		if(!cmdFile.exists)
			throw new ArgumentError("cmd执行文件：" + cmdPath + " 不存在.");
		
		var path:String = exePath.indexOf(":") == -1 ? File.applicationDirectory.nativePath + "/" + exePath : exePath;
		path = path.replace(/\\/ig, "/").replace(/\/\//ig, "/");
		
		if(path.indexOf(".exe") == -1 || !(new File(path).exists))
			throw new ArgumentError("exe执行文件：" + path + " 不存在.");
		
		var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
		startupInfo.executable = cmdFile;
		var process:NativeProcess = new NativeProcess();
		process.start(startupInfo);
		
		var drive:String = path.substr(0, 2);								//盘符
		var filePath:String = path.substring(0, path.lastIndexOf("/"));		//路径
		var fileName:String = path.substr(path.lastIndexOf("/") + 1);		//文件
		//trace(drive, filePath, fileName);
		//trace("start " + (startArgs != null  ? startArgs + " " + fileName : fileName) + (exeArgs != null ? " " + exeArgs : "") + "\n");
		
		process.standardInput.writeMultiByte(drive + "\n", "gb2312");
		process.standardInput.writeMultiByte("cd " + filePath + "\n", "gb2312");
		process.standardInput.writeMultiByte("start " + (startArgs != null  ? startArgs + " " + fileName : fileName) + (exeArgs != null ? " " + exeArgs : "") + "\n", "gb2312");
		
		NativeApplication.nativeApplication.addEventListener(Event.EXITING, function(e:Event):void 
		{
			if(!process.running)	return;
			
			process.standardInput.writeMultiByte("taskkill /f /im " + fileName + "\n", "gb2312");
			process.standardInput.writeMultiByte("exit\n", "gb2312");
		});
	}
}