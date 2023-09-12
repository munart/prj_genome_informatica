%% Utilizzo dei dati di sequenziamento di nuova generazione di Illumina/Solexa
% In questo esempio viene illustrato come leggere ed eseguire operazioni di base con i dati
% prodotti da Illumina(R)/Solexa Genome Analyzer(R).


%% Introduzione
% Durante un'analisi eseguita con il software Genome Analyzer Pipeline,
% Vengono prodotti diversi file intermedi. In questo esempio, imparerai
% Come leggere e manipolare le informazioni contenute nei file di sequenza
% (|_sequence.txt|).


%% Lettura di file _sequence.txt (FASTQ)
% Il |_sequence.txt| sono file in formato FASTQ che contengono le
% letture di sequenza e i loro punteggi di qualità, dopo il taglio di qualità e
% filtraggio. È possibile utilizzare il comando |fastqinfo| per visualizzare un riepilogo di
% contenuti di un |_sequence.txt| e il file |fastqread| funzione che
% legge il contenuto del file. L'output, |reads|, è una matrice di celle di
% strutture contenenti i seguenti campi: |Intestazione|, |Sequenza| e |Qualità|.

filename = 'ilmnsolexa_sequence.txt';
info = fastqinfo(filename)
reads = fastqread(filename)

%%
% Inserisco i dati nella tabella x tramite query insert:


%%
% Poiché esiste un file di sequenza per riquadro, non è raro avere una
% raccolta di oltre 1.000 file in totale. Si consiglia di leggere il contenuto in
% blocchi usando il comando |blockread| dell'opzione |fastqread| funzione.  
% Ad esempio, è possibile leggere le prime sequenze M o le ultime sequenze M,
% o qualsiasi sequenza M nel file.

M = 150; 
N = info.NumberOfEntries; 

% fastaread restituisce i dati di sequenza dal filename di input come struttura
% blockread specifica un vettore a due elementi [m1 m2] da leggere in un blocco di voci che iniziano dalla voce m1 e terminano dalla voce m2

readsFirst = fastqread(filename, 'blockread', [1 M]) 
readsLast = fastqread(filename, 'blockread', [N-M+1, N])


%% Rilevamento della distribuzione della lunghezza delle letture di sequenza
% Una volta caricate le informazioni sulla sequenza nell'area di lavoro,
% si può determinare il numero e la lunghezza della sequenza lette e tracciare la loro
% distribuzione come segue:

seqs = {reads.Sequence};

% cellfun applica una funzione a ogni elemento in una matrice di celle

readsLen = cellfun(@length, seqs);

figure();
% figure() crea una nuova finestra della figura utilizzando i valori delle proprietà predefinite
hist(readsLen);
% hist() crea un istogramma a barre degli elementi in readsLen
xlabel('Number of bases');
% asse delle x
ylabel('Number of sequence reads');
% asse delle y
title('Length distribution of sequence reads')
% titolo grafico

%% Rilevamento della composizione di base della sequenza
% È inoltre possibile esaminare la composizione nucleotidica rilevando il numero
% delle occorrenze di ciascun tipo di base in ogni sequenza letta, come mostrato di seguito:

nt = {'A', 'C', 'G', 'T'};
% nt corrisponde ad un cell array di caratteri
pos = cell(4,N); 
% cell() è una funzione che contiene dati, in questo caso 4 e N

for i = 1:4
	pos(i,:) = strfind(seqs, nt{i});
end
% strfind cerca nella stringa, seqs, le occorrenze di una stringa più corta, nt{i},
% restituendo l'indice iniziale di ciascuna di tali occorrenze nella matrice, pos.
count = zeros(4,N);
for i = 1:4
	count(i,:) = cellfun(@length, pos(i,:));
end
% for è una funzione che permette di fare un ciclo

figure();
subplot(2,2,1); hist(count(1,:)); title('A'); ylabel('Number of sequence reads');
subplot(2,2,2); hist(count(2,:)); title('C');
subplot(2,2,3); hist(count(3,:)); title('G'); xlabel('Occurrences'); ylabel('Number of sequence reads');
subplot(2,2,4); hist(count(4,:)); title('T'); xlabel('Occurrences');
% subplot è una funzione che divide la figura corrente in riquadri rettangolari numerati per riga.

figure(); hist(count');
xlabel('Occurrences');
ylabel('Number of sequence reads');
legend('A', 'C', 'G', 'T');
title('Base distribution by nucleotide type');
% funzioni già descritte nel grafico precedente 

%% Indagine sulla distribuzione del punteggio di qualità
% Ogni sequenza letta nella casella |_sequence.txt| è associata a un punteggio.
% Il punteggio è definito come SQ = -10 * log10 (p / (1-p)), dove p è la
% probabilità di errore di una base. È possibile esaminare i punteggi di qualità
% associati alle chiamate di base convertendo il formato ASCII in un
% rappresentazione numerica e quindi tracciare la loro distribuzione, come mostrato
% sotto:

sq = {reads.Quality}; % in formato ASCII
SQ = cellfun(@(x) double(x)-64, {reads.Quality}, 'UniformOutput', false); % in formato intero

% Deviazione media, mediana e standard 

avgSQ = cellfun(@mean, SQ);
medSQ = cellfun(@median, SQ);
stdSQ = cellfun(@std, SQ);

% Distribuzione del grafico della qualità mediana e media

figure(); 
subplot(1,2,1); hist(medSQ); 
xlabel('Median Score SQ'); ylabel('Number of sequence reads');
subplot(1,2,2); boxplot(avgSQ); ylabel('Average Score SQ');
% funzioni già descritte nel grafico precedente
 
%% Conversione dei punteggi di qualità tra standard
% I punteggi di qualità trovati nei file Solexa/Illumina sono asintotici, ma non
% identici ai punteggi di qualità utilizzati nello standard Sanger (Phred-like
% punteggi, Q). Q è definito come -10 * log10 (p), dove p è l'errore
% probabilità di una base.
% Mentre i punteggi di qualità Phred sono numeri interi positivi, nella qualità Solexa/Illumina i punteggi 
% possono essere negativi. Possiamo convertire i punteggi di qualità Solexa in Phred
% di punteggi di qualità utilizzando il seguente codice:

% convertire da Solexa a Sanger standard

Q = cellfun(@(x) floor(.499 + 10 * log10(1+ 10 .^ (x/10))), SQ, ...
	'UniformOutput', false); % in formato intero
q = cellfun(@(x) char(x+33), Q, 'UniformOutput', false); % in formato ASCII

sanger = q(1:3)'
solexa = sq(1:3)'

%% Filtraggio e mascheramento in base ai punteggi di qualità
% Il filtraggio della purezza del segnale è già stato applicato alle sequenze nella
% |_sequence.txt| ﬁle. È possibile eseguire filtri aggiuntivi, ad esempio
% considerando solo quelle letture di sequenza le cui basi hanno tutte le qualità
% di punteggi superiori a una determinata soglia:

% find sequence reads le cui basi hanno tutte una qualità superiore alla soglia
len = 36;
qt = 10; % Soglia minima di qualità
a = cellfun(@(x) x > qt, SQ, 'UniformOutput', false); 
b = cellfun(@sum, a);
c1 = find(b == len);
n1= numel(c1); % Numero di letture di sequenza che passano il filtro
disp([num2str(n1) ' sequence reads have all bases above threshold ' num2str(qt)]);
% disp visualizza il valore di cio nelle () senza stampare il nome del valore

%%
% In alternativa, è possibile considerare solo le letture di sequenza che hanno meno di un
% dato numero di basi con punteggi di qualità inferiori alla soglia:

% find sequence reads aventi basi inferiori a M con qualità inferiore alla soglia
M = 5; % Numero massimo di basi di scarsa qualità
a = cellfun(@(x) x <= qt, SQ, 'UniformOutput', false); 
b = cellfun(@sum, a);
c2 = find(b <= M);
n2 = numel(c2); % Numero di letture di sequenza che passano il filtro
% numel() restituisce il numero di elementi, numUnique, nella matrice uReads, equivalente a PROD

disp([num2str(n2) ' sequence reads have less than ' num2str(M) ' bases below threshold ' num2str(qt)]);

%%
% Infine, è possibile applicare una maschera minuscola a quelle basi che hanno
% punteggi di qualità al di sotto della soglia:

seq = reads(1).Sequence
mseq = seq;
qt2 = 20;  % Soglia di qualità
mask = SQ{1} < qt;
mseq(mask) = lower(seq(mask))
% lower() converte i caratteri maiuscoli nella stringa (seq(mask)) nei caratteri minuscoli corrispondenti.

%% Riepilogo delle occorrenze di lettura 
% Per riepilogare le occorrenze di lettura, è possibile determinare il numero di
% sequenze di lettura e la loro distribuzione nel set di dati. Puoi anche
% identificare quelle letture di sequenza che si verificano più volte, spesso perché
% corrispondono agli adattatori o primer utilizzati nel processo di sequenziamento.

% Determinare la frequenza di lettura
[uReads,~,n] = unique({reads.Sequence});
% Unique() restituisce gli stessi dati di reads.Sequence, ma senza ripetizioni. [uReads,~,n] è in ordine ordinato.
numUnique = numel(uReads)
readFreq = accumarray(n(:),1);
% accumarray somma gruppi di dati accumulando elementi di un dato vettoriale secondo i gruppi specificati
figure(); hist(readFreq, unique(readFreq)); 
xlabel('Occurrences'); ylabel('Number of sequence reads');
title('Read occurrences');
% funzioni già descritte nel grafico precedente

% Identificare le letture di sequenze che si verificano in modo multiplo
d = readFreq > 1;
dupReads = uReads(d)'
dupFreq  = readFreq(d)'

%% Identificazione degli artefatti omopolimerici
% Il sequenziamento Illumina/Solexa può produrre falsi polyA ai bordi di un
% riquadro. Per identificare questi artefatti, è necessario identificare gli omopolimeri,
% cioè, la sequenza legge composta da un solo tipo di nucleotide. Nel
% set di dati in esame, ci sono due omopolimeri, entrambi i quali sono poliA.
% Trova omopolimeri

pc = (count ./ len) * 100;
[homopolType,homopolIndex] = find(pc == 100);

homopolIndex
homopol = {reads(homopolIndex).Sequence}'

%%
% Allo stesso modo, è possibile identificare letture di sequenze che corrispondono quasi a
% omopolimeri, cioè letture di sequenza composte quasi
% esclusivamente di un tipo di nucleotide.
% Trova quasi-omopolimeri

[nearhomopolType, nearhomopolIndex] = find(pc < 100 & pc > 85); % più dell'85% della stessa base
nearhomopolIndex
nearHomopol = {reads(nearhomopolIndex).Sequence}'

%% Scrittura di dati in formato FASTQ
% Una volta elaborati e analizzati i dati, potrebbe essere conveniente
% il salvataggio di un sottoinsieme di sequenze in un file FASTQ separato per il futuro
% di corrispettivo. A tale scopo è possibile utilizzare il comando |fastqwrite| funzione.
