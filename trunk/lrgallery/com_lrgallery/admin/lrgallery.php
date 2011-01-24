<?php

    defined('_JEXEC') or die('Restricted access');
    
    JLoader::register('LrgalleryHelper', dirname(__FILE__) . DS . 'helpers' . DS . 'lrgallery.php');

    $document = JFactory::getDocument();    
    
    jimport('joomla.application.component.controller');

    $controller = JController::getInstance('lrgallery');
    $controller->execute(JRequest::getCmd('task'));
    $controller->redirect();
?>