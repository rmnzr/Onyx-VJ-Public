package onyx.patch.cpu {
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	
	import onyx.core.*;
	import onyx.display.*;
	import onyx.event.*;
	import onyx.parameter.*;
	import onyx.plugin.*;
	
	use namespace parameter;
	
	[Parameter(type='color',		id='color', 		target='format/color')]
	[Parameter(type='number',		id='size', 			target='format/size',	clamp='6,350')]
	[Parameter(type='font',			id='font', 			target='format/font')]
	[Parameter(type='boolean',		id='embedFonts', 	target='label/embedFonts')]
	[Parameter(type='text',			id='text', 			target='label/text')]

	final public class TextPatch extends PluginPatchTransformCPU {
		
		/**
		 * 	@private
		 */
		parameter const label:TextField		= new TextField();
		
		/**
		 * 	@private
		 */
		parameter const format:TextFormat	= new TextFormat(null, 28, 0xFFFFFF);

		/**
		 * 	@public
		 */
		override public function initialize(context:IDisplayContextCPU, channel:IChannelCPU, path:IFileReference, content:Object):PluginStatus {
			
			dimensions.width 		= context.width;
			dimensions.height		= context.height;
			
			label.autoSize			= TextFieldAutoSize.LEFT;
			label.antiAliasType		= AntiAliasType.ADVANCED;
			label.text				= '';
			label.defaultTextFormat	= format;
			label.embedFonts		= true;
			
			// success
			return super.initialize(context, channel, path, content);
		}
		
		/**
		 * 	@public
		 */
		override protected function validate(invalidParameters:Object):void {
			
			label.setTextFormat(format);
			label.defaultTextFormat = format;
			
		}
		
		/**
		 * 	@public
		 */
		override public function update(time:Number):Boolean {
			return invalid;
		}

		/**
		 * 	@public
		 */
		override public function render(context:IDisplayContextCPU):Boolean {
			
			context.clear();
			context.draw(label, renderMatrix, null, null, null, true, StageQuality.HIGH_8X8);
			
			// return
			return true;
		}
		
		/**
		 * 	@public
		 */
		override public function dispose():void {
			
			super.dispose();

		}
	}
}