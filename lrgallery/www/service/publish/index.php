<?php

require_once('PublishHelper.php');
$xmlVar = 'lrgalleryxml';

$helper = new PublishHelper();
$helper->parse($xmlVar);
$helper->call();
echo $helper->getXmlResult();
