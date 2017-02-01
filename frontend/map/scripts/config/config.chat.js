var colorPallette = require('../constants/stylusPallette.coffee');
var app = require('../app.coffee');

//attempted to put this in a local var but it does not work
window._chatlio = window._chatlio||[];

!function(){ var t=document.getElementById("chatlio-widget-embed");if(t&&window.ChatlioReact&&_chatlio.init)return void _chatlio.init(t,ChatlioReact);for(var e=function(t){return function(){_chatlio.push([t].concat(arguments)) }},i=["configure","identify","track","show","hide","isShown","isOnline"],a=0;a<i.length;a++)_chatlio[i[a]]||(_chatlio[i[a]]=e(i[a]));var n=document.createElement("script"),c=document.getElementsByTagName("script")[0];n.id="chatlio-widget-embed",n.src="https://w.chatlio.com/w.chatlio-widget.js",n.async=!0,n.setAttribute("data-embed-version","2.1");
  //- n.setAttribute('data-widget-options', '{"embedSidebar": true}');
  n.setAttribute('data-widget-id','7f1b3bb2-caf0-4133-7d56-1f201b428c54');
  c.parentNode.insertBefore(n,c);
}();


_chatlio.configure({
  "style": 'chip',
  "titleColor": colorPallette.$dark_blue_darker,
  "titleFontColor": colorPallette.$white,
  "onlineTitle": "Need help?",
  "offlineTitle": "Contact Us"
});

app.run(function($rootScope, rmapsEventConstants){
  $rootScope.$on(rmapsEventConstants.principal.login.success, function() {

    var watcher = $rootScope.$watch('user', function(user){
      if(!user)
        return;

      watcher();
      window._chatlio.identify(user.email, {
        'name': user.full_name,
        'email': user.email,
        'plan': user.stripe_plan_id
      });
    });



  });
});




module.exports = _chatlio;
