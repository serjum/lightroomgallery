<?php
    
    /*** Инициализируем Joomla Framework ***/
    define('_JEXEC', 1);
    define('DS', DIRECTORY_SEPARATOR);

    if (!defined('_JDEFINES')) {
        define('JPATH_BASE', dirname(dirname(dirname(__FILE__))));
        require_once JPATH_BASE . DS . 'includes' . DS . 'defines.php';
    }
    require_once JPATH_BASE . DS . 'includes' . DS . 'framework.php';
    
    $app = JFactory::getApplication('site');
    $app->initialise();

    // Подключаем нужные библиотеки
    jimport('joomla.filesystem.file');
    jimport('joomla.utilities.simplexml');
    jimport('joomla.application.component.helper');

    /*
     * Вспомогательный класс для работы с xml rpc
     */
    class PublishHelper {
        
        private $data = null;
        private $result = null;
        private $error = null;
                
        /*
         * Разбор содержимого XML
         */
        public function parse($xmlVar) {
            
            // Получим содержимое
            $content = $_POST[$xmlVar];            
            
            if (empty($content)) {
                $this->error = new JException('XML content is empty', 1);
                return $this->error;
            }
            
            // Если включены magic quotes, уберем escape слэши
            if (get_magic_quotes_gpc()) {
                $content = stripslashes($content);
            }          

            // Попробуем разобрать его как XML
            $parser = new JSimpleXML();
            if (!$parser->loadString($content)) {
                $this->error = new JException('Error occured while parsing XML', 1);
                return $this->error;
            }
            
            // Найдём метод
            $method = $parser->document->methodName[0]->data();
            $this->data->method = $method;           
            
            // Найдём параметры
            $this->data->params = array();
            foreach ($parser->document->params[0]->children() as $param) {
                $keyValues = $param->value[0]->children();
                $keyValue = $keyValues[0];
                $this->data->params[$keyValue->name()] = $keyValue->data();
            }
            
            // Если в параметрах присутствует изображение, 
            // декодируем его из base64 и запишем во временный файл
            if (array_key_exists('image', $this->data->params)) {
                $data = $this->urlsafe_b64decode($this->data->params['image']);
                $file = tempnam(sys_get_temp_dir(), 'lrgallery_');
                JFile::write($file, $data);
                
                // Переименуем файл
                $oldName = basename($file);
                $newName = $this->data->params['filename'];
                $newPath = str_replace($oldName, $newName, $file);
                JFile::move($file, $newPath);
                
                $this->data->params['filename'] = $newPath;
                unset($this->data->params['image']);                
            }
        }
        
        private function urlsafe_b64encode($string) {
            $data = base64_encode($string);
            $data = str_replace(array('+', '/', '='), array('-', '_', ''), $data);
            return $data;
        }

        private function urlsafe_b64decode($string) {
            $data = str_replace(array('-', '_'), array('+', '/'), $string);
            $mod4 = strlen($data) % 4;
            if ($mod4) {
                $data .= substr('====', $mod4);
            }
            return base64_decode($data);
        }
        
        /*
         * Вызов метода, определённого в разобранном XML файле
         */
        public function call() {
            
            // Получим сервисный контроллер
            $controllerName = 'LrgalleryControllerService';
            define('JPATH_COMPONENT', JPATH_BASE . DS . 'components' . DS . 'com_lrgallery');
            require_once(JPATH_COMPONENT . DS . 'controllers' . DS . 'service.php');
            $controller = new $controllerName();
            
            // Выберем нужные параметры вызываемого метода при помощи рефлексии
            $method = new ReflectionMethod($controllerName, $this->data->method);
            $params = array();
            foreach ($method->getParameters() as $reflectionParam) {
                $params[] = $this->data->params[$reflectionParam->name];
            }
            
            // Вызовем метод с нужными параметрами
            $result = call_user_func_array(array($controller, $this->data->method), $params);
            if (JError::isError($result))
                $this->error = $result;
            else
                $this->result = $result;
            
        }
        
        /*
         * Получение результата в формате XML
         */
        public function getXmlResult() {
            $xml =      '<?xml version="1.0"?>';
            $xml .=     "<methodResponse>";
            $xml .=     "   <params>";
            foreach ($this->result as $key => $value) {
                $xml .= "       <param>";
                $xml .= "           <value>";
                $xml .= "               <$key>$value</$key>";
                $xml .= "           </value>";
                $xml .= "       </param>";
            }
            $xml .=     "   </params>";
            $xml .=     "   <errors>";
            if (!empty($this->error)) {
                $code = $this->error->getCode();
                $message = $this->error->getMessage();
                
                $xml .= "       <error>";
                $xml .= "           <code>$code</code>";
                $xml .= "           <message>$message</message>";
                $xml .= "       </error>";
            }
            $xml .=     "   </errors>";
            $xml .=     "</methodResponse>";

            return $xml;
        }
    }
?>
