# 前端面试笔记

1. 谈谈你之前做过的你认为比较满意的项目？在其中担任什么角色？

1. 谈谈你对前端标准化的认识？你前端代码的组织方式？模块化开发？

1. 谈谈使用过的常用的前端框架

1. 用纯CSS实现一个三列等高布局

1. 用bootstrap实现一个模态框

1. JSONP跨域请求的实现原理

1. iframe跨域传值解决方法

1. DOM的默认事件、事件模型、事件委托、阻止默认事件、冒泡事件的方式等。

1. 请实现以下函数

		add(2)(5); //7

1. 请说明要输出正确的myName的值要如何修改程序?并解释原因
	
		var foo = function(){
		    this.myName = "Foo function.";
		}
		foo.prototype.sayHello = function(){
		    alert(this.myName);
		}
		foo.prototype.bar = function(){
		    setTimeout(this.sayHello, 1000);
		}
		var f = new foo();
		f.bar();
