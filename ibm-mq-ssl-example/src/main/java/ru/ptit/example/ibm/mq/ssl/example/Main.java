package ru.ptit.example.ibm.mq.ssl.example;

import java.nio.file.FileSystems;
import java.nio.file.Path;
import java.nio.file.Paths;

import javax.jms.Connection;

import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.wmq.WMQConstants;

public class Main
{

    private static final class Config
    {
        private String host = "localhost";
        private Integer port = 1414;
        private String queueManager = "QM1";
        private String channel = "QM1.SVRCONN";

        private String sslciph = "SSL_RSA_WITH_RC4_128_MD5";
        private String sslpass = "passw0rd";

        private int ccsid = 1208;
        private boolean fipsRequired = false;;
        private String sslPeerName = "CN=*";

        private String disableSSLv3 = Boolean.FALSE.toString();
        private String overrideDefaultTLS = Boolean.TRUE.toString();
        private String preferTLS = Boolean.TRUE.toString();
        private String useIBMCipherMappings = Boolean.TRUE.toString();;
        private String disabledAlgorithms = "";
        private String debugSSL = "all";//all
    }

    public static void main(String[] args)
        throws Exception
    {
        Config config = new Config();
        
        Path keystorePath = Paths.get(".").resolve("..").resolve("ssl").resolve("keystore").resolve("cfkeystore.jks").toAbsolutePath();
        System.setProperty("javax.net.ssl.trustStore", keystorePath.toString());
        System.setProperty("javax.net.ssl.keyStore", keystorePath.toString());
        System.setProperty("javax.net.ssl.keyStorePassword", config.sslpass);
        
        MQQueueConnectionFactory mqQueueConnectionFactory = new MQQueueConnectionFactory();
        mqQueueConnectionFactory.setHostName(config.host);
        // INIT SSL
        System.setProperty("com.ibm.jsse2.disableSSLv3", config.disableSSLv3);
        System.setProperty("com.ibm.jsse2.overrideDefaultTLS", config.overrideDefaultTLS);
        System.setProperty("com.ibm.mq.cfg.preferTLS", config.preferTLS);
        System.setProperty("com.ibm.mq.cfg.useIBMCipherMappings", config.useIBMCipherMappings);
        System.setProperty("javax.net.debug", config.debugSSL);

        java.security.Security.setProperty("jdk.tls.disabledAlgorithms", config.disabledAlgorithms.trim());

        mqQueueConnectionFactory.setSSLCipherSuite(config.sslciph);
        mqQueueConnectionFactory.setTransportType(WMQConstants.WMQ_CM_CLIENT);
        mqQueueConnectionFactory.setCCSID(config.ccsid);
        mqQueueConnectionFactory.setChannel(config.channel);
        mqQueueConnectionFactory.setPort(config.port);
        mqQueueConnectionFactory.setSSLFipsRequired(config.fipsRequired);
        mqQueueConnectionFactory.setSSLPeerName(config.sslPeerName);
        mqQueueConnectionFactory.setQueueManager(config.queueManager);

        Connection c = mqQueueConnectionFactory.createConnection();
        System.out.println("Connected!");
        System.out.println("Connection Info:");
        System.out.println(c.getMetaData());
        c.close();
        System.out.println("Disconnected!");
    }

}
