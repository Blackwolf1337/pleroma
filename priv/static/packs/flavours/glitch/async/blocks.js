(window.webpackJsonp=window.webpackJsonp||[]).push([[45],{676:function(t,e,a){"use strict";a.r(e),a.d(e,"default",function(){return y});var c,o,n,s=a(1),i=a(7),l=a(0),r=a(2),d=(a(3),a(20)),u=a(26),b=a.n(u),p=a(5),j=a.n(p),O=a(290),h=a(300),f=a(641),g=a(645),v=a(625),m=a(106),k=a(6),w=a(24),S=Object(k.f)({heading:{id:"column.blocks",defaultMessage:"Blocked users"}}),y=Object(d.connect)(function(t){return{accountIds:t.getIn(["user_lists","blocks","items"])}})(c=Object(k.g)((n=o=function(o){function t(){for(var a,t=arguments.length,e=new Array(t),c=0;c<t;c++)e[c]=arguments[c];return a=o.call.apply(o,[this].concat(e))||this,Object(r.a)(Object(l.a)(Object(l.a)(a)),"handleScroll",function(t){var e=t.target;e.scrollTop===e.scrollHeight-e.clientHeight&&a.props.dispatch(Object(m.c)())}),Object(r.a)(Object(l.a)(Object(l.a)(a)),"shouldUpdateScroll",function(t,e){var a=e.location;return!(((t||{}).location||{}).state||{}).mastodonModalOpen&&!(a.state&&a.state.mastodonModalOpen)}),a}Object(i.a)(t,o);var e=t.prototype;return e.componentWillMount=function(){this.props.dispatch(Object(m.d)())},e.render=function(){var t=this.props,e=t.intl,a=t.accountIds;return a?Object(s.a)(f.a,{name:"blocks",icon:"ban",heading:e.formatMessage(S.heading)},void 0,Object(s.a)(g.a,{}),Object(s.a)(h.a,{scrollKey:"blocks",shouldUpdateScroll:this.shouldUpdateScroll},void 0,Object(s.a)("div",{className:"scrollable",onScroll:this.handleScroll},void 0,a.map(function(t){return Object(s.a)(v.a,{id:t},t)})))):Object(s.a)(f.a,{},void 0,Object(s.a)(O.a,{}))},t}(w.a),Object(r.a)(o,"propTypes",{params:j.a.object.isRequired,dispatch:j.a.func.isRequired,accountIds:b.a.list,intl:j.a.object.isRequired}),c=n))||c)||c}}]);
//# sourceMappingURL=blocks.js.map