(window.webpackJsonp=window.webpackJsonp||[]).push([[72],{667:function(t,e,n){"use strict";n.r(e),n.d(e,"default",function(){return y});var s,a,c,i=n(1),o=n(7),r=n(0),u=n(2),d=n(3),l=n.n(d),p=n(20),b=n(5),f=n.n(b),h=n(26),j=n.n(h),O=n(281),g=n(641),m=n(645),w=n(647),M=n(6),I=n(24),R=Object(M.f)({heading:{id:"column.pins",defaultMessage:"Pinned toot"}}),y=Object(p.connect)(function(t){return{statusIds:t.getIn(["status_lists","pins","items"]),hasMore:!!t.getIn(["status_lists","pins","next"])}})(s=Object(M.g)((c=a=function(a){function t(){for(var e,t=arguments.length,n=new Array(t),s=0;s<t;s++)n[s]=arguments[s];return e=a.call.apply(a,[this].concat(n))||this,Object(u.a)(Object(r.a)(Object(r.a)(e)),"handleHeaderClick",function(){e.column.scrollTop()}),Object(u.a)(Object(r.a)(Object(r.a)(e)),"setRef",function(t){e.column=t}),e}Object(o.a)(t,a);var e=t.prototype;return e.componentWillMount=function(){this.props.dispatch(Object(O.b)())},e.render=function(){var t=this.props,e=t.intl,n=t.statusIds,s=t.hasMore;return l.a.createElement(g.a,{icon:"thumb-tack",heading:e.formatMessage(R.heading),ref:this.setRef},Object(i.a)(m.a,{}),Object(i.a)(w.a,{statusIds:n,scrollKey:"pinned_statuses",hasMore:s}))},t}(I.a),Object(u.a)(a,"propTypes",{dispatch:f.a.func.isRequired,statusIds:j.a.list.isRequired,intl:f.a.object.isRequired,hasMore:f.a.bool.isRequired}),s=c))||s)||s}}]);
//# sourceMappingURL=pinned_statuses.js.map