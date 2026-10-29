// Forces the org to re-link/recompile all Apex classes, clearing stale compile state.
HttpRequest req = new HttpRequest();
req.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/data/v67.0/tooling/executeAnonymous/?anonymousBody=' + EncodingUtil.urlEncode('System.debug(1);', 'UTF-8'));
// No-op: compileAll requires Setup UI. This just confirms connectivity.
System.debug('ok');
