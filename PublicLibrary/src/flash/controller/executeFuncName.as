package flash.controller
{
	import flash.utils.getDefinitionByName;

	/**
	 *	 执行动态函数
	 * @param model
	 * @param properties
	 * @param args
	 * @param ignoreError
	 */	
	/*[Deprecated(message="放弃吧??")]*/
	public function executeFuncName(model:Object, properties:String, args:String = null, ignoreError:Boolean = false):*
	{
		if(model == null || properties == null || properties == "")	return null;
		var tm:Object = (model is String && model.indexOf(".") != -1) ? getDefinitionByName(model.toString()) : model;
		
		var props:Array = properties.split(".");
		var pORf:String = props.splice(props.length - 1, 1);	//提出属性或方法名称
		
		/**	@internal	查找公共子级对象	*/
		for(var i:int = 0; i < props.length; i ++)
		{
			if(tm.hasOwnProperty(props[i]))
			{
				tm = tm[props[i]];
			}					
			else
			{
				if(ignoreError)	
					trace("Error 不存在可访问的子级对象:" + props[i] + " [" + properties + "]");
				else
					throw new Error("不存在可访问的子级对象:" + props[i] + " [" + properties + "]");
				
				return null;
			}
		}
		/**	@internal	检查对象是否已经定义了指定的属性		*/
		if(!tm.hasOwnProperty(pORf))
		{
			if(ignoreError)	
				trace("Error 对象或子级对象不存在的属性或方法:" + pORf +" [" + properties + "]");
			else
				throw new Error("对象或子级对象不存在的属性或方法:" + pORf +" [" + properties + "]");
			
			return null;
		}
		
		/**	@internal	检查对象属性是函数还是属性对象		*/
		if(tm[pORf] is Function)
		{
			return tm[pORf].apply(tm, args is String ? args.split(",") : args is Array ? args : [args]);
		}
		else
		{
			if(args != null)	tm[pORf] = args;
			return tm[pORf];
		}
		
		return null;
	}
}