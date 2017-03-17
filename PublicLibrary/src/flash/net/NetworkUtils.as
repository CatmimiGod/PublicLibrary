package flash.net
{
	import flash.events.Event;
	import flash.utils.getDefinitionByName;
	
	//import flash.net.NetworkInfo;
	//import flash.net.NetworkInterface;
	//import flash.net.InterfaceAddress;

	//import com.adobe.nativeExtensions.Networkinfo.InterfaceAddress;
	//import com.adobe.nativeExtensions.Networkinfo.NetworkInfo;
	//import com.adobe.nativeExtensions.Networkinfo.NetworkInterface;
	
	/**
	 *	网络功能类 
	 * @author Administrator
	 */	
	public class NetworkUtils
	{
		/**
		 *	 网络接口MAC物理地址(hardwareAddress)正则表达式
		 */		
		public static const HA_REGEXP:RegExp = /^([[:xdigit:]]{2}[-:]){5}[[:xdigit:]]{2}$/i;
		
		/**
		 *	网络接口IP地址正则表达式 
		 */		
		public static const IP_REGEXP:RegExp = /^(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])$/;
		
		private static var _networkInterfaces:Vector.<Object>;
		
		/**
		 *	分析本机所有可用的网络接口对象，移除了非活动状态、127.0.0.1的网络接口。
		 * 	@return 返回可用的网络接口对象
		 */		
		public static function analyseAvailableInterface():Vector.<Object>
		{
			/*
			if(!NetworkInfo.isSupported)		return null;			
			var networkInfo:Object = NetworkInfo.networkInfo.findInterfaces();
			
			if(!flash.net.NetworkInfo.networkInfo.hasEventListener(Event.NETWORK_CHANGE))
				flash.net.NetworkInfo.networkInfo.addEventListener(Event.NETWORK_CHANGE, onNetworkChnageHandler);
			*/
			
			var networkInfo:Object;
			if(flash.net.NetworkInfo.isSupported)
			{
				networkInfo = getDefinitionByName('flash.net.NetworkInfo')['networkInfo']['findInterfaces']();
				
				if(!flash.net.NetworkInfo.networkInfo.hasEventListener(Event.NETWORK_CHANGE))
					flash.net.NetworkInfo.networkInfo.addEventListener(Event.NETWORK_CHANGE, onNetworkChnageHandler);
			}
			else
			{
				networkInfo = getDefinitionByName('com.adobe.nativeExtensions.Networkinfo.NetworkInfo')['networkInfo']['findInterfaces']();
			}
			
			
			if(_networkInterfaces != null)
				_networkInterfaces = null;
			
			_networkInterfaces = new Vector.<Object>();
			
			for each (var interfaceObj:Object in networkInfo)
			{
				if(!interfaceObj.active)	continue;
				if(interfaceObj.addresses.length == 0)	continue;
				if(!(HA_REGEXP.test(interfaceObj.hardwareAddress)))	continue;
				
				for each (var address:Object in interfaceObj.addresses)
				{
					if(address.address == "127.0.0.1")		break;
					//if(address.ipVersion.toUpperCase() == "IPV6" || address.address == "127.0.0.1")		break;
				}
				
				_networkInterfaces.push(interfaceObj);
			}
			
			return _networkInterfaces;
		}
		private static function onNetworkChnageHandler(e:Event):void
		{
			analyseAvailableInterface();
		}
		
		/**
		 *	 跟据IP段，获取网络接口内所有同段的可用IP地址；没有IP段则返回所有可用IP地址。
		 * 
		 * @param ipAddrSegment	IP地址段，例如：getAddress("192.168.1")或getAddress("10.10.2.101")
		 * @return 返回IP地址，多个IP地址以","隔开
		 */		
		public static function getAddress(ipAddrSegment:String = null):String
		{
			if(_networkInterfaces == null)	return null;
			
			var ipAddress:String = "";
			if(ipAddrSegment != null && IP_REGEXP.test(ipAddrSegment))
				ipAddrSegment = ipAddrSegment.substring(0, ipAddrSegment.lastIndexOf("."));
				
			for each (var interfaceObj:Object in _networkInterfaces)
			{
				for each (var address:Object in interfaceObj.addresses)
				{
					if(address.ipVersion.toUpperCase() == "IPV6" || address.address == "127.0.0.1")	continue;
					
					if(ipAddrSegment == null)
					{
						if(ipAddress != "")	ipAddress += ",";
						ipAddress += address.address;
						
						continue;
					}
					
					if(address.address.indexOf(ipAddrSegment) == 0)
					{
						if(ipAddress != "")	ipAddress += ",";
						ipAddress += address.address;
					}
				}
			}
			
			return ipAddress != "" ? ipAddress : null;
		}
		
		/**
		 *	跟据IP地址，获取对应IP地址的物理地址；没有IP地址，则返回所有可用的物理地址
		 * 
		 * @param ipAddress	IP地址
		 * @throws ArgurmentError	IP地址格式错误
		 * @return 返回物理地址，多个以","隔开
		 */		
		public static function getHardwareAddress(ipAddress:String = null):String
		{
			if(ipAddress != null && !IP_REGEXP.test(ipAddress))
				throw new ArgumentError("参数错误，IP地址不格式错误。");
			
			if(_networkInterfaces == null)	return null;
			
			var isFind:Boolean = false;
			var hardwareAddress:String = "";
			
			for each (var interfaceObj:Object in _networkInterfaces)
			{
				if(ipAddress == null)
				{
					if(hardwareAddress != "")	hardwareAddress += ",";
					hardwareAddress += interfaceObj.hardwareAddress;
					
					continue;
				}
				
				isFind = false;
				for each (var address:Object in interfaceObj.addresses)
				{
					if(address.address == ipAddress)
					{
						isFind = true;
						break;
					}
				}
				
				if(isFind)
				{
					hardwareAddress = interfaceObj.hardwareAddress;
					break;
				}
			}
			
			return hardwareAddress != "" ? hardwareAddress : null;
		}
		
		
	}
}