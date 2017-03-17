package flash.controller
{
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;
	import flash.system.fscommand;
	import flash.utils.getDefinitionByName;
	import flash.utils.setTimeout;
	
	public class DemoUtils
	{
		
		/**
		 *	退出演示程序，此方法只针对Window系统 
		 */		
		public static function exit():void
		{
			if(Capabilities.os.toLowerCase().indexOf("win") == -1)
				return;
			
			switch(Capabilities.playerType)
			{
				case "ActiveX":		//用于 Microsoft Internet Explorer 使用的 Flash Player ActiveX 控件
					ExternalInterface.call("exit");
					break;
				
				case "StandAlone":	//用于独立的 Flash Player
					fscommand("quit");
					break;
				
				case "Desktop":		//代表 Adobe AIR 运行时（通过 HTML 页加载的 SWF 内容除外，该内容将 Capabilities.playerType 设置为“PlugIn”）
					var cls:Class = getDefinitionByName("flash.desktop.NativeApplication") as Class;
					cls.nativeApplication.exit();
					break;
			}
		}
		
		/**
		 * 重启演示程序，此方法只针对Window系统 
		 * @param obj	此参数只针对 Desktop 桌面程序
		 */
		public static function restart():void
		{
			if(Capabilities.os.toLowerCase().indexOf("win") == -1)
				return;
			
			switch(Capabilities.playerType)
			{
				case "ActiveX":		//用于 Microsoft Internet Explorer 使用的 Flash Player ActiveX 控件
					ExternalInterface.call("restart");
					break;
				
				case "StandAlone":	//用于独立的 Flash Player
					trace("暂时不支持.");
					break;
				
				//case "External":
				case "Desktop":		//代表 Adobe AIR 运行时（通过 HTML 页加载的 SWF 内容除外，该内容将 Capabilities.playerType 设置为“PlugIn”）
					var NativeProcess:Class = getDefinitionByName("flash.desktop.NativeProcess") as Class;
					if(!NativeProcess.isSupported)	return;
					
					//var url:String = obj.loaderInfo.url;
					//var fileName:String = url.substr(url.lastIndexOf("/") + 1, url.length).replace(".swf", ".exe");
					
					//获取fileName
					var NativeApplication:Class = getDefinitionByName("flash.desktop.NativeApplication") as Class;					
					var applicationDescriptor:XML = NativeApplication.nativeApplication.applicationDescriptor;
					var ns:Namespace = applicationDescriptor.namespace();
					var fileName:String = applicationDescriptor.ns::filename + ".exe";
					trace(fileName);
					//File
					var File:Class = getDefinitionByName("flash.filesystem.File") as Class;
					var cmdFile:Object = new File(File.applicationDirectory.nativePath + "/modules/process.exe");
					if(!cmdFile.exists) return;
					
					var currentFileName:String = File.applicationDirectory.nativePath + "\\" + fileName;
					trace(currentFileName);
					var NativeProcessStartupInfo:Class = getDefinitionByName("flash.desktop.NativeProcessStartupInfo") as Class;
					var processInfo:Object = new NativeProcessStartupInfo();
					processInfo.executable = cmdFile;
					processInfo.arguments = new <String>["-start", currentFileName, "", "2"];
					
					var process:Object = new NativeProcess();
					process.start(processInfo);
					
					setTimeout(exit, 200);
					break;
			}
		}
		
		public static function startup(path:String):void
		{
			
		}
		
	}
}