//+------------------------------------------------------------------+
//|                                                   LadinotBot.mqh |
//|                                                   Rodrigo Landim |
//|                                        http://www.emagine.com.br |
//+------------------------------------------------------------------+
#property copyright "Rodrigo Landim"
#property link      "http://www.emagine.com.br"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <LadinoBot/Utils.mqh>
#include <LadinoBot/Views/LogPanel.mqh>
#include <LadinoBot/Strategies/HiLo.mqh>
#include <LadinoBot/Trade/LTrade.mqh>
   
//+------------------------------------------------------------------+

class LadinoBase: public LTrade {
   private:
      int _diaAtual; //, _fractalHandle;
      
      // Parametros
      ENUM_SITUACAO_ROBO      _statusAtual;
      ENUM_HORARIO            _HorarioEntrada;
      ENUM_HORARIO            _HorarioFechamento;
      ENUM_HORARIO            _HorarioSaida;
      ENUM_ATIVO              _TipoAtivo;
      ENUM_RISCO              _GestaoRisco;
      ENUM_ENTRADA            _CondicaoEntrada;
      double                  _ValorPonto;
      double                  _ganhoMaximoPosicao;

      void inicializarVariavel();
      void inicializarParametro();
   protected:
      bool tendenciaMudou, posicionado;
      
      ENUM_OPERACAO_SITUACAO  _operacaoAtual;
      ENUM_OPERACAO           _TipoOperacao;
      int                     _InicialVolume;
      double                  _volumeAtual;
      double                  _precoCompra, _precoVenda;
      double                  _ultimoStopMax;
      int                     _MaximoVolume;
      
      void inicializarBasico();
   public:
      LadinoBase(void);
      
      ENUM_SITUACAO_ROBO getStatusAtual();
      
      void ativar();
      void fechar();

      void desativar();
      void atualizarPreco();
      
      void alterarOperacaoAtual();

      void onTick();
      void onTimer();
      double onTester();
      
      virtual bool verificarEntrada();
      virtual bool verificarSaida();
      
      ENUM_HORARIO getHorarioEntrada();
      void setHorarioEntrada(ENUM_HORARIO value);
      ENUM_HORARIO getHorarioFechamento();
      void setHorarioFechamento(ENUM_HORARIO value);
      ENUM_HORARIO getHorarioSaida();
      void setHorarioSaida(ENUM_HORARIO value);
      ENUM_OPERACAO getTipoOperacao();
      void setTipoOperacao(ENUM_OPERACAO value);
      ENUM_ATIVO getTipoAtivo();
      void getTipoAtivo(ENUM_ATIVO value);
      ENUM_RISCO getGestaoRisco();
      void setGestaoRisco(ENUM_RISCO value);
      ENUM_ENTRADA getCondicaoEntrada();
      void setCondicaoEntrada(ENUM_ENTRADA value);
      double getValorPonto();
      void setValorPonto(double value);
      int getInicialVolume();
      void setInicialVolume(int value);
      int getMaximoVolume();
      void setMaximoVolume(int value);
      double getGanhoMaximoPosicao();
      void setGanhoMaximoPosicao(double valor);
};

LadinoBase::LadinoBase(void) {
   inicializarVariavel();
   inicializarParametro();
}

ENUM_SITUACAO_ROBO LadinoBase::getStatusAtual() {
   return _statusAtual;
}

void LadinoBase::inicializarBasico() {
   MqlDateTime tempo;
   TimeToStruct(iTimeMQL4(_Symbol,_Period,0), tempo);
   _diaAtual = tempo.day_of_year;
   _statusAtual = INICIALIZADO;
   if (horarioCondicao(_HorarioEntrada, IGUAL_OU_MAIOR_QUE) && horarioCondicao(_HorarioFechamento, IGUAL_OU_MENOR_QUE))
      ativar();       
}

void LadinoBase::inicializarVariavel() {
   _volumeAtual = 0;

   tendenciaMudou = false;
   posicionado = false;

   _precoCompra = 0;
   _precoVenda = 0;

   _operacaoAtual = SITUACAO_FECHADA;

   _ultimoStopMax = 0;
   _diaAtual = 0;

   //_fractalHandle = 0;

   _statusAtual = INATIVO;
}

void LadinoBase::inicializarParametro() {
   _HorarioEntrada = HORARIO_1000;
   _HorarioFechamento = HORARIO_1600;
   _HorarioSaida = HORARIO_1630;
   _TipoOperacao = COMPRAR_VENDER;
   _TipoAtivo = ATIVO_INDICE;
   _GestaoRisco = RISCO_NORMAL;
   _CondicaoEntrada = HILO_CRUZ_MM_T1_FECHAMENTO;
   _ValorPonto = 0.2;
   
   _InicialVolume = 1;
   _MaximoVolume = 1;
}

void LadinoBase::ativar() {
   if (_statusAtual != ATIVO) {
      _statusAtual = ATIVO;
      //escreverLog("LadinoBot active for trading!");
      escreverLog(INFO_BOT_ACTIVE);
      
      double volMinimo = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
      double volMaximo = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
      double volPasso = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
      
      _volumeAtual = _InicialVolume;
      _volumeAtual = _volumeAtual - MathMod(_volumeAtual, volPasso);
      
      if (_volumeAtual < volMinimo)
         _volumeAtual = volMinimo;
      if (_volumeAtual > volMaximo)
         _volumeAtual = volMaximo;
         
      //escreverLog("Volume " + IntegerToString((int) _volumeAtual) + " to be traded...");
      escreverLog(StringFormat(INFO_VOLUME, (int)_volumeAtual));
   }
}

void LadinoBase::fechar() {
   if (_statusAtual != FECHANDO) {
      _statusAtual = FECHANDO;
      //escreverLog("LadinoBot closed to new trades! Current Financial = " + StringFormat("%.2f", this.getTotal()));
      escreverLog(StringFormat(INFO_CLOSED_NEW_TRADES, MoneyToString(this.getTotal())));
   }
}

void LadinoBase::desativar() {
   if (_statusAtual != INATIVO) {
      _statusAtual = INATIVO;
      if(PositionSelect(_Symbol)) {
         //escreverLog("Disabling LadinoBot, closing all open positions.");
         escreverLog(INFO_CLOSING_ALL_POSITIONS);
         this.finalizarPosicao();
      }
      //escreverLog("LadinoBot disabled for trading! Current Financial =" + StringFormat("%.2f", this.getTotal()));
      escreverLog(StringFormat(INFO_BOT_DISABLE, MoneyToString(this.getTotal())));
   }
}

void LadinoBase::alterarOperacaoAtual() {
   if (_operacaoAtual == SITUACAO_ABERTA || _operacaoAtual == SITUACAO_BREAK_EVEN)
      _operacaoAtual = SITUACAO_OBJETIVO1;
   else if (_operacaoAtual == SITUACAO_OBJETIVO1)
      _operacaoAtual = SITUACAO_OBJETIVO2;
   else if (_operacaoAtual == SITUACAO_OBJETIVO2)
      _operacaoAtual = SITUACAO_OBJETIVO3;
}

void LadinoBase::atualizarPreco() {
   // Preço atual
   double tickMinimo = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double preco = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   preco = NormalizeDouble(preco, _Digits);
   preco = preco - MathMod(preco, tickMinimo);
   if (preco != _precoCompra)
      _precoCompra = preco;
   
   preco = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   preco = NormalizeDouble(preco, _Digits);
   preco = preco - MathMod(preco, tickMinimo);
   if (preco != _precoVenda)
      _precoVenda = preco;
}

void LadinoBase::onTick() {
   if (_statusAtual == ATIVO) {
      if(PositionSelect(_Symbol))
         verificarSaida();
      else
         verificarEntrada();
   }
   else if (_statusAtual == FECHANDO) {
      if(PositionSelect(_Symbol))
         verificarSaida();
   }
}

void LadinoBase::onTimer() {
   MqlDateTime tempo;
   TimeToStruct(iTimeMQL4(_Symbol,_Period,0), tempo);
   if (_diaAtual != tempo.day_of_year) {
      this.fecharDia();
      _statusAtual = INICIALIZADO;
      _diaAtual = tempo.day_of_year;
   }
   
   if (_statusAtual == INICIALIZADO) {
      if (horarioCondicao(getHorarioEntrada(), IGUAL_OU_MAIOR_QUE))
         ativar();      
   }   
   else if (_statusAtual == ATIVO) {
      if (horarioCondicao(getHorarioFechamento(), IGUAL_OU_MAIOR_QUE))
         fechar();
      if (horarioCondicao(getHorarioSaida(), IGUAL_OU_MAIOR_QUE))
         desativar();
   }
   else if (_statusAtual == INATIVO) {

   }
   else if (_statusAtual == FECHANDO) {
      if (horarioCondicao(getHorarioSaida(), IGUAL_OU_MAIOR_QUE))
         desativar();
   }
}

double LadinoBase::onTester() {
   this.fecharDia();
   /*
   string msg = "TESTE FINALIZADO!";
   msg += " s/f=" + IntegerToString(this.getSucessoTotal()) + "/" + IntegerToString(this.getFalhaTotal());
   msg += ", c=" + StringFormat("%.2f", this.getCorretagemTotal()) + ".";
   msg += ", $=" + StringFormat("%.2f", this.getTotal());
   escreverLog(msg);
   */
   escreverLog(StringFormat(
      INFO_TEST_FINISH,
      this.getSucessoTotal(),
      this.getFalhaTotal(),
      MoneyToString(this.getCorretagemTotal()),
      MoneyToString(this.getTotal())
   ));
   return 0;
}

//+------------------------------------------------------------------+

bool LadinoBase::verificarEntrada() {
   return false;
}
bool LadinoBase::verificarSaida() {
   return false;
}

ENUM_HORARIO LadinoBase::getHorarioEntrada() {
   return _HorarioEntrada;
}

void LadinoBase::setHorarioEntrada(ENUM_HORARIO value) {
   _HorarioEntrada = value;
}

ENUM_HORARIO LadinoBase::getHorarioFechamento() {
   return _HorarioFechamento;
}

void LadinoBase::setHorarioFechamento(ENUM_HORARIO value) {
   _HorarioFechamento = value;
}

ENUM_HORARIO LadinoBase::getHorarioSaida(){
   return _HorarioSaida;
}

void LadinoBase::setHorarioSaida(ENUM_HORARIO value) {
   _HorarioSaida = value;
}

ENUM_OPERACAO LadinoBase::getTipoOperacao() {
   return _TipoOperacao;
}

void LadinoBase::setTipoOperacao(ENUM_OPERACAO value) {
   _TipoOperacao = value;
}

ENUM_ATIVO LadinoBase::getTipoAtivo() {
   return _TipoAtivo;
}

void LadinoBase::getTipoAtivo(ENUM_ATIVO value) {
   _TipoAtivo = value;
}

ENUM_RISCO LadinoBase::getGestaoRisco() {
   return _GestaoRisco;
}

void LadinoBase::setGestaoRisco(ENUM_RISCO value) {
   _GestaoRisco = value;
}

ENUM_ENTRADA LadinoBase::getCondicaoEntrada() {
   return _CondicaoEntrada;
}

void LadinoBase::setCondicaoEntrada(ENUM_ENTRADA value) {
   _CondicaoEntrada = value;
}

double LadinoBase::getValorPonto() {
   return _ValorPonto;
}

void LadinoBase::setValorPonto(double value) {
   _ValorPonto = value;
}

int LadinoBase::getInicialVolume() {
   return _InicialVolume;
}

void LadinoBase::setInicialVolume(int value) {
   _InicialVolume = value;
}

int LadinoBase::getMaximoVolume() {
   return _MaximoVolume;
}

void LadinoBase::setMaximoVolume(int value) {
   _MaximoVolume = value;
}

double LadinoBase::getGanhoMaximoPosicao() {
   return _ganhoMaximoPosicao;
}

void LadinoBase::setGanhoMaximoPosicao(double valor) {
   _ganhoMaximoPosicao = valor;
}